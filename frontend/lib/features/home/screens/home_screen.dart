import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:books_read/core/constants.dart';
import 'package:books_read/features/library/screens/book_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final double rating;
  final List<String> genres;
  final Color coverColor;
  final String fileUrl;
  final String? imageUrl; // 👑 ADDED: Optional cover artwork string path

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.rating,
    required this.genres,
    required this.coverColor,
    required this.fileUrl,
    this.imageUrl, // Handle optional parameters cleanly
  });


  factory Book.fromJson(Map<String, dynamic> json) {
    var rawGenres = json['genres'];
    List<String> parsedGenres = [];
    if (rawGenres is List) {
      parsedGenres = rawGenres.map((g) => g.toString()).toList();
    } else if (rawGenres is String && rawGenres.isNotEmpty) {
      parsedGenres = [rawGenres];
    }

    Color parsedColor = Colors.blue;
    final hexString = json['cover_color'] ?? json['coverColor'];
    if (hexString != null && hexString.toString().startsWith('#')) {
      try {
        final hexValue = int.parse(hexString.toString().replaceFirst('#', '88'));
        parsedColor = Color(hexValue);
      } catch (_) {}
    } else {
      final id = json['id'] ?? 0;
      final fallbackColors = [Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.teal];
      parsedColor = fallbackColors[id % fallbackColors.length];
    }

    return Book(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled Book',
      author: json['author'] ?? 'Unknown Author',
      rating: double.tryParse(json['rating']?.toString() ?? '4.5') ?? 4.5,
      genres: parsedGenres.isEmpty ? ['General'] : parsedGenres,
      coverColor: parsedColor,
      // 👑 Dynamic URL match fallback linking your backend static folder assets or online sample dummy file
      fileUrl: json['file_url'] ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      imageUrl: json['image_url'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _books = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _userFavoriteBooks = [];
  List<dynamic> _userLibraryBooks = [];

  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0;
  final List<String> _tabs = ['Books', 'Authors', 'Categories'];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final booksUri = Uri.parse('http://192.168.100.166:8000/api/books/');
      final booksResponse = await http.get(booksUri, headers: {'Content-Type': 'application/json'});

      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token') ?? prefs.getString('token');

      List<dynamic> favorites = [];
      List<dynamic> library = [];

      if (token != null) {
        final profileUri = Uri.parse('http://192.168.100.166:8000/api/auth/profile/');
        final profileResponse = await http.get(profileUri, headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        });

        if (profileResponse.statusCode == 200) {
          final Map<String, dynamic> profileData = jsonDecode(profileResponse.body);
          favorites = profileData['favorites_books'] ?? [];
          library = profileData['my_library_books'] ?? [];
        }
      }

      if (!mounted) return;

      if (booksResponse.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(booksResponse.body);
        setState(() {
          _books = responseData.map((json) => Book.fromJson(json)).toList();
          _userFavoriteBooks = favorites;
          _userLibraryBooks = library;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load library data (${booksResponse.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not connect to backend server.';
        _isLoading = false;
      });
    }
  }

  List<Book> get _filteredBooks {
    final query = _searchController.text.toLowerCase();
    return _books.where((book) {
      return book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
    }).toList();
  }

  List<String> get _filteredAuthors {
    final query = _searchController.text.toLowerCase();
    return _books
        .map((b) => b.author)
        .toSet()
        .where((author) => author.toLowerCase().contains(query))
        .toList()
      ..sort();
  }

  List<String> get _filteredCategories {
    final query = _searchController.text.toLowerCase();
    return _books
        .expand((b) => b.genres)
        .toSet()
        .where((genre) => genre.toLowerCase().contains(query))
        .toList()
      ..sort();
  }

  int _bookCountForAuthor(String author) =>
      _books.where((b) => b.author == author).length;

  int _bookCountForCategory(String category) =>
      _books.where((b) => b.genres.contains(category)).length;

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            hintText: 'Search books, authors...',
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBooksView() {
    final books = _filteredBooks;
    if (books.isEmpty) {
      return const Center(
        child: Text('No books found.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: books.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          onTap: () async {
            final bool isFav = _userFavoriteBooks.any((json) => json['id'] == book.id);
            final bool isRead = _userLibraryBooks.any((json) => json['id'] == book.id);

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(
                  book: book,
                  initialIsFavorite: isFav,
                  initialIsRead: isRead,
                ),
              ),
            );

            _fetchInitialData();
          },
          leading: Container(
            width: 40,
            height: 50,
            decoration: BoxDecoration(
              color: book.coverColor,
              borderRadius: BorderRadius.circular(4),
              // 👑 ADD THIS: Renders the web image layout if it exists!
              image: book.imageUrl != null
                  ? DecorationImage(
                image: NetworkImage(book.imageUrl!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            // Show a tiny clean book icon if there is no image uploaded yet
            child: book.imageUrl == null
                ? const Center(
              child: Icon(Icons.book, size: 18, color: Colors.white38),
            )
                : null,
          ),
          title: Text(book.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(book.author, style: const TextStyle(color: Colors.grey)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                book.rating.toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthorsView() {
    final authors = _filteredAuthors;
    if (authors.isEmpty) {
      return const Center(
        child: Text('No authors found.', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: authors.length,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) {
        final author = authors[index];
        final count = _bookCountForAuthor(author);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blueGrey,
            child: Text(
              author.isNotEmpty ? author[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(author, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            '$count book${count == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildCategoriesView() {
    final categories = _filteredCategories;
    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories found.', style: TextStyle(color: Colors.grey)),
      );
    }

    final categoryColors = [
      Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.green, Colors.teal, Colors.pink, Colors.indigo,
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 70,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final count = _bookCountForCategory(category);
        final color = categoryColors[index % categoryColors.length];
        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                '$count book${count == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildMainBodyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBodyState() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchInitialData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }

    return switch (_selectedTab) {
      0 => _buildBooksView(),
      1 => _buildAuthorsView(),
      2 => _buildCategoriesView(),
      _ => const SizedBox(),
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}