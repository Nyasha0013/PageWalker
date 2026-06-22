import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import '../../core/config/supabase_config.dart';
import '../models/book.dart';
import 'catalog_book_repository.dart';

class BookRepository {
  final _client = SupabaseConfig.client;
  final _catalog = CatalogBookRepository();

  Future<List<Book>> searchBooks(String query) async {
    final list = await _catalog.searchAll(query);
    return list.map(Book.fromCatalogBook).toList();
  }

  Future<Book?> getBookById(String bookId) async {
    final cached = await _client
        .from('books')
        .select()
        .eq('id', bookId)
        .maybeSingle();
    if (cached != null) return Book.fromSupabase(cached);

    final stableId = bookId.startsWith('google_') ? bookId : 'google_$bookId';
    final catalogBook = await _catalog.getByCatalogId(stableId);
    if (catalogBook != null) {
      final book = Book.fromCatalogBook(catalogBook);
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
    if (Env.hasPagewalkerBooksApi) {
      try {
        final response = await http
            .post(
              Uri.parse('${Env.apiBaseUrl}/api/mood-recommendations'),
              headers: const {
                'Content-Type': 'application/json',
                'User-Agent': 'Pagewalker/6.0 Flutter',
              },
              body: jsonEncode({'mood': moodInput}),
            )
            .timeout(const Duration(seconds: 35));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final recommendations =
              data['recommendations'] as List<dynamic>? ?? [];
          final books = <Book>[];
          for (final rec in recommendations) {
            final map = rec as Map<String, dynamic>;
            final title = '${map['title'] ?? ''}'.trim();
            final author = '${map['author'] ?? ''}'.trim();
            if (title.isEmpty) continue;

            final results = await _catalog.searchAll('$title $author');
            if (results.isNotEmpty) {
              books.add(Book.fromCatalogBook(results.first));
              continue;
            }

            books.add(
              Book(
                id: 'mood_${title.toLowerCase().hashCode}',
                title: title,
                author: author.isEmpty ? 'Unknown Author' : author,
                coverUrl: map['coverUrl'] as String?,
                description: map['reason'] as String?,
                genres: [
                  if (map['genre'] != null) '${map['genre']}',
                ],
              ),
            );
          }
          if (books.isNotEmpty) return books;
        }
      } catch (_) {
        // fall through to direct OpenAI when configured
      }
    }

    if (!Env.hasOpenAiKey) return [];

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

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;
    final recommendations = jsonDecode(content) as List<dynamic>;

    final books = <Book>[];
    for (final rec in recommendations) {
      final query = '${rec["title"]} ${rec["author"]}';
      final results = await _catalog.searchAll(query);
      if (results.isNotEmpty) {
        books.add(Book.fromCatalogBook(results.first));
      }
    }
    return books;
  }
}
