import 'package:flutter/material.dart';
// 👑 FIXED IMPORTS: Points directly to where your home_screen and book_detail_screen live
import 'package:books_read/features/home/screens/home_screen.dart';
import 'package:books_read/features/library/screens/book_detail_screen.dart';

class BookListScreen extends StatelessWidget {
  final String title;
  final List<dynamic> books;

  const BookListScreen({
    super.key,
    required this.title,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1C1F2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: books.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              "No books in this collection yet.",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final bookData = books[index];

          // Parse dynamic server hex color string cleanly
          Color coverColor = Colors.blueGrey;
          try {
            final hexStr = bookData['cover_color'].replaceAll('#', '');
            coverColor = Color(int.parse('FF$hexStr', radix: 16));
          } catch (_) {}

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1F2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 50,
                height: 75,
                decoration: BoxDecoration(
                  color: coverColor,
                  borderRadius: BorderRadius.circular(6),
                  image: bookData['image_url'] != null
                      ? DecorationImage(
                    image: NetworkImage(bookData['image_url']),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: bookData['image_url'] == null
                    ? const Center(child: Icon(Icons.book, size: 20, color: Colors.white38))
                    : null,
              ),
              title: Text(
                bookData['title'] ?? 'Unknown Title',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  bookData['author'] ?? 'Unknown Author',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // Maps properties safely to your frontend schema
                final Book clickedBook = Book(
                  id: bookData['id'] ?? 0,
                  title: bookData['title'] ?? 'Unknown Title',
                  author: bookData['author'] ?? 'Unknown Author',
                  rating: double.tryParse(bookData['rating']?.toString() ?? '4.5') ?? 4.5,
                  genres: List<String>.from(bookData['genres'] ?? []),
                  coverColor: coverColor,
                  fileUrl: bookData['file_url'] ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                  imageUrl: bookData['image_url'],
                );

                bool isFav = title == 'Favorites Collection';
                bool isRead = title == 'Custom Lists';

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(
                      book: clickedBook,
                      initialIsFavorite: isFav,
                      initialIsRead: isRead,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}