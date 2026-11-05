import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 🚀 Added to read stored token
import 'core/theme.dart';
import 'features/auth/screens/get_started.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/main_wrapper.dart';
import 'api_config.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized(); // 🚀 Required to initialize native storage plugins early
  runApp(const BookoraApp());
}

class BookoraApp extends StatelessWidget {
  const BookoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bookora',
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const GetStartedPage(),
        '/get-started': (context) => const GetStartedPage(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => MainWrapper(),
      },
    );
  }
}

class BackendConnectionWrapper extends StatefulWidget {
  const BackendConnectionWrapper({super.key});

  @override
  State<BackendConnectionWrapper> createState() => _BackendConnectionWrapperState();
}

class _BackendConnectionWrapperState extends State<BackendConnectionWrapper> {
  bool _isLoading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Run your background backend connection test
    await _checkBackendConnection();

    // 2. 👑 Read the saved token from device memory!
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      debugPrint("🔑 Stored session found! Token: $token");
      _hasToken = true;
    } else {
      debugPrint("ℹ️ No token found. User needs to authenticate.");
      _hasToken = false;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkBackendConnection() async {
    // Ensure this matches your active computer network IP!
    final url = Uri.parse(
        '$apiBaseUrl/api/books/'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        debugPrint("⚡ Success: Connected to Django Backend!");
      } else {
        debugPrint("⚠️ Backend reached, status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Backend Connection Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 3. Show a dark loading canvas while the app checks memory logs
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF12141C),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    // 4. Decision Engine: Route to dashboard if session exists, otherwise show intro layout
    return _hasToken ? MainWrapper() : const GetStartedPage();
  }
}