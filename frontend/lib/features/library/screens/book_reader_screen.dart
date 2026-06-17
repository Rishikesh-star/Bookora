import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class BookReaderScreen extends StatefulWidget {
  final String bookTitle;
  final String fileUrl;

  const BookReaderScreen({
    super.key,
    required this.bookTitle,
    required this.fileUrl,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  String? _errorMessage;

  int _totalPages = 0;
  int _currentPage = 0;
  bool _pdfReady = false;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadAndCachePdf();
  }

  // Securely streams the file from your Django server into temporary app storage cache
  Future<void> _downloadAndCachePdf() async {
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();

        // Generates a localized safe path instance
        final file = File('${dir.path}/book_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes, flush: true);

        if (!mounted) return;
        setState(() {
          _localFilePath = file.path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Server refused file stream (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to sync document viewer system.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        elevation: 0,
        title: Text(widget.bookTitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_pdfReady)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "${_currentPage + 1} / $_totalPages",
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            )
        ],
      ),
      body: _buildReaderContent(),
    );
  }

  Widget _buildReaderContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text("Downloading pages safely...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
      );
    }

    return PDFView(
      filePath: _localFilePath,
      enableSwipe: true,
      swipeHorizontal: true, // Set to false if you want vertical scrolling instead!
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
          _pdfReady = true;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = error.toString();
        });
      },
      onPageError: (page, error) {
        debugPrint('Page $page error: ${error.toString()}');
      },
      onViewCreated: (PDFViewController pdfViewController) {
        _pdfViewController = pdfViewController;
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          _currentPage = page ?? 0;
        });
      },
    );
  }
}