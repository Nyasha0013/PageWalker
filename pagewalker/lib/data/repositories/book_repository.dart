import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import '../../core/config/supabase_config.dart';
import '../models/book.dart';

class BookRepository {
  final _client = SupabaseConfig.client;
  final String _googleBooksBase = 'https://www.googleapis.com/books/v1';

  Future<List<Book>> searchBooks(String query) async {
    final response = await http.get(
      Uri.parse(
        '$_googleBooksBase/volumes?q=${Uri.encodeComponent(query)}&maxResults=20&key=${Env.googleBooksApiKey}',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map(
            (e) => Book.fromGoogleBooks(e as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<Book?> getBookById(String bookId) async {
    // Check Supabase cache first
    final cached = await _client
        .from('books')
        .select()
        .eq('id', bookId)
        .maybeSingle();
    if (cached != null) return Book.fromSupabase(cached);

    // Fetch from Google Books
    final response = await http.get(
      Uri.parse(
        '$_googleBooksBase/volumes/$bookId?key=${Env.googleBooksApiKey}',
      ),
    );
    if (response.statusCode == 200) {
      final book = Book.fromGoogleBooks(jsonDecode(response.body));
      await _client.from('books').upsert(book.toSupabase());
      return book;
    }
    return null;
  }

  Future<List<Book>> getMoodRecommendations({
    required String moodInput,
    required List<String> topBooks,
    required List<String> topTropes,
  }) async {
    final response = await http.post(
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
                'You are Pagewalker\'s magical book guide. Return only valid JSON array, no extra text.',
          },
          {
            'role': 'user',
            'content':
                'Reader feels: "$moodInput". Top books: ${topBooks.join(", ")}. Fave tropes: ${topTropes.join(", ")}. Recommend 5 books as JSON with keys: title, author, reason.',
          },
        ],
        'max_tokens': 800,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content =
          data['choices'][0]['message']['content'] as String;
      final recommendations =
          jsonDecode(content) as List<dynamic>;

      // Search Google Books for each recommendation
      final books = <Book>[];
      for (final rec in recommendations) {
        final query = '${rec["title"]} ${rec["author"]}';
        final results = await searchBooks(query);
        if (results.isNotEmpty) books.add(results.first);
      }
      return books;
    }
    return [];
  }
}

