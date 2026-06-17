import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:books_read/features/home/screens/home_screen.dart';

// 👑 IMPORT: Add this so this screen knows how to find your reading view file!
import 'book_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final bool initialIsFavorite;
  final bool initialIsRead;

  const BookDetailScreen({
    super.key,
    required this.book,
    this.initialIsFavorite = false,
    this.initialIsRead = false,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late bool _isFavorite;
  late bool _isRead;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
    _isRead = widget.initialIsRead;
  }

  Future<void> _toggleBookStatus(String action) async {
    if (_isActionLoading) return;

    setState(() {
      _isActionLoading = true;
    });

    final http.Client isolatedClient = http.Client();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token') ?? prefs.getString('token');

      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication expired. Please log in again.")),
        );
        return;
      }

      final url = Uri.parse('http://192.168.100.166:8000/api/profile/update-book/');
      final response = await isolatedClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'book_id': widget.book.id,
          'action': action,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        setState(() {
          if (action == 'favorite') {
            _isFavorite = !_isFavorite;
          } else if (action == 'library') {
            _isRead = !_isRead;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Status updated successfully!'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server responded with error (${response.statusCode})")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not connect to book management pipeline.")),
      );
    } finally {
      isolatedClient.close();
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _isActionLoading ? null : () => _toggleBookStatus('favorite'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 160,
                height: 240,
                decoration: BoxDecoration(
                  color: book.coverColor, // Background placeholder color
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: book.coverColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                  // 👑 NEW: Checks if the image exists, loading it over network
                  image: book.imageUrl != null
                      ? DecorationImage(
                    image: NetworkImage(book.imageUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                // Show a nice icon placeholder if the book doesn't have an image uploaded yet
                child: book.imageUrl == null
                    ? const Center(
                  child: Icon(Icons.book, size: 50, color: Colors.white54),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'By ${book.author}',
              style: const TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  book.rating.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(' / 5.0', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: book.genres.map((genre) {
                return Chip(
                  label: Text(genre),
                  backgroundColor: Colors.blue.withOpacity(0.15),
                  labelStyle: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600),
                  side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isRead ? Colors.green : Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isActionLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    )
                        : Icon(
                      _isRead ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: _isRead ? Colors.green : Colors.grey,
                    ),
                    label: Text(
                      _isRead ? 'Marked Read' : 'Mark as Read',
                      style: TextStyle(color: _isRead ? Colors.green : Colors.white),
                    ),
                    onPressed: _isActionLoading ? null : () => _toggleBookStatus('library'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Spacer under Mark Read row

            // 👑 FIXED EXTRA COMPONENT: Start Reading Live Navigation Trigger
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
                label: const Text(
                    'Start Reading Now',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookReaderScreen(
                        bookTitle: book.title,
                        fileUrl: book.fileUrl,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32), // Spacer right before Synopsis


          ],
        ),
      ),
    );
  }
}