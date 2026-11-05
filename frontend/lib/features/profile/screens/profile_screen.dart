import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api_config.dart';
import 'book_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _username = 'Reader';
  String _email = '';
  int _favoritesCount = 0;
  int _libraryCount = 0;

  // 👑 Holds the raw JSON book arrays received from Django
  List<dynamic> _rawFavoriteBooks = [];
  List<dynamic> _rawLibraryBooks = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfileStats();
  }

  Future<void> _fetchProfileStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final http.Client isolatedClient = http.Client();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token') ?? prefs.getString('token');

      if (token == null) {
        setState(() {
          _errorMessage = "Authentication session expired. Please log in again.";
          _isLoading = false;
        });
        return;
      }
      final url = Uri.parse(
          '$apiBaseUrl/api/auth/profile/'
      );

      final response = await isolatedClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        print("DEBUG PROFILE RESPONSE BODY: ${response.body}");

        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _username = data['username'] ?? 'User';
          _email = data['email'] ?? '';

          // 👑 Store the actual lists into our state variables
          _rawLibraryBooks = data['my_library_books'] ?? [];
          _rawFavoriteBooks = data['favorites_books'] ?? [];

          // Parse metrics based on lists
          _libraryCount = _rawLibraryBooks.isNotEmpty ? _rawLibraryBooks.length : (data['library_count'] ?? 0);
          _favoritesCount = _rawFavoriteBooks.isNotEmpty ? _rawFavoriteBooks.length : (data['favorites_count'] ?? 0);

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load profile details (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Could not synchronize dashboard statistics.";
        _isLoading = false;
      });
    } finally {
      isolatedClient.close();
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token');

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF12141C),
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF12141C),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _fetchProfileStats, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.blue,
          backgroundColor: const Color(0xFF1C1F2E),
          onRefresh: _fetchProfileStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blueGrey,
                    child: Text(
                      _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_username, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_email, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 32),

                // Real-Time Statistics Container
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1F2E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildStatItem('$_libraryCount', 'My Lists'),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[800]),
                      Expanded(
                        child: _buildStatItem('$_favoritesCount', 'Favorites'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Menu Actions Elements with explicit Routing
                _buildMenuItem(
                  Icons.favorite_border,
                  'Favorites Collection',
                  Colors.redAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookListScreen(
                          title: 'Favorites Collection',
                          books: _rawFavoriteBooks,
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.bookmark_outline,
                  'Custom Lists',
                  Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookListScreen(
                          title: 'Custom Lists',
                          books: _rawLibraryBooks,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                    onPressed: _handleLogout,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1C1F2E), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}