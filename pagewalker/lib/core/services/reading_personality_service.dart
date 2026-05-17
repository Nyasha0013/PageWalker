import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

class ReadingPersonalityService {
  ReadingPersonalityService._();
  static final instance = ReadingPersonalityService._();

  static const _cacheTextKey = 'personality_description_';
  static const _cacheCountKey = 'personality_cached_book_count_';

  Future<String> getDescription({
    required String userId,
    required List<String> topTropes,
    required int booksRead,
    required double avgRating,
  }) async {
    if (topTropes.isEmpty) {
      return 'Keep reading to discover your personality!';
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedText = prefs.getString('$_cacheTextKey$userId');
    final cachedCount = prefs.getInt('$_cacheCountKey$userId');

    if (cachedText != null &&
        cachedCount != null &&
        (booksRead - cachedCount).abs() < 5) {
      return cachedText;
    }

    if (Env.hasOpenAiKey) {
      try {
        final response = await http
            .post(
              Uri.parse('https://api.openai.com/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer ${Env.openAiKey}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': 'gpt-4o-mini',
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are a fun, witty book personality analyser for a BookTok-style app. '
                        'Be warm and concise.',
                  },
                  {
                    'role': 'user',
                    'content':
                        'This reader has read $booksRead books with an average rating of '
                        '${avgRating.toStringAsFixed(1)} stars. '
                        'Their top genres/tropes are: ${topTropes.take(4).join(", ")}. '
                        'Write a fun 2-sentence reading personality description for them. '
                        'Start with a fun title like "The [Archetype] Reader" then describe them.',
                  },
                ],
                'max_tokens': 120,
              }),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final text = (data['choices'] as List<dynamic>? ?? []).isEmpty
              ? null
              : (data['choices'][0] as Map<String, dynamic>)['message']
                  as Map<String, dynamic>?;
          final content = text?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            await prefs.setString('$_cacheTextKey$userId', content.trim());
            await prefs.setInt('$_cacheCountKey$userId', booksRead);
            return content.trim();
          }
        }
      } catch (e) {
        // openai failed, use local copy
      }
    }

    final top = topTropes.first;
    return "You're a die-hard $top reader. Your shelves tell a story of someone who reads with intention — keep going!";
  }
}
