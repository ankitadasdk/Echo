import 'dart:convert';
import 'package:http/http.dart' as http;

class BookMetadata {
  final String title;
  final String author;
  final int pageCount;
  final String coverUrl;

  BookMetadata({
    required this.title,
    required this.author,
    required this.pageCount,
    required this.coverUrl,
  });
}

class BookService {
  static Future<BookMetadata?> searchBook(String query) async {
    final url = Uri.parse('https://openlibrary.org/search.json?q=${Uri.encodeComponent(query)}&limit=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['docs'] != null && data['docs'].isNotEmpty) {
          final book = data['docs'][0];
          return BookMetadata(
            title: book['title'] ?? 'Unknown Title',
            author: book['author_name'] != null ? book['author_name'][0] : 'Unknown Author',
            pageCount: book['number_of_pages_median'] ?? 300, // default fallback
            coverUrl: book['cover_i'] != null 
                ? 'https://covers.openlibrary.org/b/id/${book['cover_i']}-M.jpg'
                : '',
          );
        }
      }
    } catch (e) {
      print('Error fetching book: $e');
    }
    return null;
  }
}
