
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

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
  PdfController? _pdfController;

  bool _isLoading = true;
  String? _errorMessage;

  int _totalPages = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  // Download PDF bytes from Cloudinary.
  Future<Uint8List> _loadPdfBytes() async {
    final response = await http.get(
      Uri.parse(widget.fileUrl),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download PDF. HTTP ${response.statusCode}',
      );
    }

    if (response.bodyBytes.isEmpty) {
      throw Exception('The downloaded PDF is empty.');
    }

    return response.bodyBytes;
  }

  // Load the downloaded PDF into the viewer.
  Future<void> _loadPdf() async {
    try {
      final bytes = await _loadPdfBytes();

      final document = await PdfDocument.openData(bytes);

      final controller = PdfController(
        document: Future.value(document),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _pdfController = controller;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load PDF: $e';
        _isLoading = false;
      });

      debugPrint('PDF loading error: $e');
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12141C),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F2E),
        elevation: 0,

        title: Text(
          widget.bookTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        actions: [
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Center(
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),

      body: _buildReaderContent(),
    );
  }

  Widget _buildReaderContent() {
    // Loading indicator.
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Loading your book...',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Error message.
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  _loadPdf();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // PDF viewer.
    if (_pdfController == null) {
      return const Center(
        child: Text(
          'PDF viewer is unavailable.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return PdfView(
      controller: _pdfController!,
      scrollDirection: Axis.horizontal,

      onDocumentLoaded: (document) {
        if (!mounted) return;

        setState(() {
          _totalPages = document.pagesCount;
        });
      },

      onPageChanged: (page) {
        if (!mounted) return;

        setState(() {
          _currentPage = page;
        });
      },
    );
  }
}
