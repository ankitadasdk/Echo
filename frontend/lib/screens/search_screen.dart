import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/book_service.dart';
import 'reading_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  bool _isLoading = false;

  void _searchAndStart() async {
    if (_searchController.text.isEmpty || _roomController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final _book = await BookService.searchBook(_searchController.text);
    setState(() => _isLoading = false);

    if (_book != null && mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => ReadingScreen(
            book: _book,
            roomId: _roomController.text,
          ),
          transitionsBuilder: (context, anim1, anim2, child) {
            return FadeTransition(opacity: anim1, child: child);
          },
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Book not found on Open Library'),
            backgroundColor: Colors.redAccent.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background Bubbles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF8B5CF6),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(end: 50, duration: 4.seconds),
          ),
          Positioned(
            bottom: -50,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF06B6D4),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveX(end: 50, duration: 5.seconds),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 64, color: Colors.white)
                            .animate().fade().scale(curve: Curves.easeOutBack, delay: 200.ms),
                        const SizedBox(height: 16),
                        const Text(
                          'Echo Sync',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ).animate().fade().slideY(begin: 0.2, end: 0, delay: 300.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Peer-to-peer Buddy Reading',
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                        ).animate().fade(delay: 400.ms),
                        const SizedBox(height: 40),
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter Book Title (e.g. Dune)',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          ),
                        ).animate().fade().slideX(begin: 0.1, end: 0, delay: 500.ms),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _roomController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter Buddy Room Code',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.group, color: Colors.white70),
                          ),
                        ).animate().fade().slideX(begin: 0.1, end: 0, delay: 600.ms),
                        const SizedBox(height: 32),
                        _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF06B6D4))
                            : Container(
                                width: double.infinity,
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _searchAndStart,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text(
                                    'Start Sync',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ).animate().fade().slideY(begin: 0.2, end: 0, delay: 700.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
