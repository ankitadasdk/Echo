import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/book_service.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import '../services/webrtc_service.dart';
import '../models/models.dart';
import 'package:uuid/uuid.dart';

class ReadingScreen extends StatefulWidget {
  final BookMetadata book;
  final String roomId;
  
  const ReadingScreen({super.key, required this.book, required this.roomId});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  int _currentPage = 1;
  late WebRTCService _webRTCService;
  bool _isConnected = false;
  final _noteController = TextEditingController();

  List<GhostAnnotation> _annotations = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadAnnotations();
    _initWebRTC();
  }
  
  void _loadProgress() {}

  void _loadAnnotations() {
    if (!mounted) return;
    setState(() {
      _annotations = StorageService.annotationsBox.values.where((a) => a.bookId == widget.book.title).toList();
    });
  }

  void _initWebRTC() async {
    _webRTCService = WebRTCService(serverUrl: 'ws://127.0.0.1:8000', roomId: widget.roomId);
    
    _webRTCService.onConnectionStateChange = (connected) {
      if (mounted) setState(() => _isConnected = connected);
    };

    _webRTCService.onMessageReceived = (payload) {
      if (payload['type'] == 'annotation') {
        _receiveAnnotation(
          payload['page'], 
          payload['payload'], 
          payload['id']
        );
      }
    };

    await _webRTCService.connect();
  }
  
  void _receiveAnnotation(int page, String encryptedData, String id) {
    if (!StorageService.annotationsBox.values.any((a) => a.id == id)) {
      final newNote = GhostAnnotation(
        id: id,
        bookId: widget.book.title,
        pageNumber: page,
        encryptedPayload: encryptedData,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      StorageService.annotationsBox.add(newNote);
      _loadAnnotations();
    }
  }

  void _postNote() {
    if (_noteController.text.isEmpty) return;
    
    final encrypted = CryptoService.encryptPayload(_noteController.text, widget.roomId, _currentPage);
    final id = const Uuid().v4();
    
    final newNote = GhostAnnotation(
      id: id,
      bookId: widget.book.title,
      pageNumber: _currentPage,
      encryptedPayload: encrypted,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    StorageService.annotationsBox.add(newNote);
    _loadAnnotations();
    
    _webRTCService.sendMessage({
      'type': 'annotation',
      'id': id,
      'page': _currentPage,
      'payload': encrypted,
    });
    
    _noteController.clear();
    Navigator.pop(context); 
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E).withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF06B6D4)),
              const SizedBox(width: 8),
              Text('Note for Page $_currentPage', style: const TextStyle(fontSize: 18, color: Colors.white)),
            ],
          ),
          content: TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Encrypt your thought...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _postNote, 
              child: const Text('Post to Mesh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ],
        ),
      ).animate().fadeIn().scale(curve: Curves.easeOutBack)
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPageNotes = _annotations.where((a) => a.pageNumber == _currentPage).toList();
    final futureNotes = _annotations.where((a) => a.pageNumber > _currentPage).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Room: ${widget.roomId}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isConnected ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(_isConnected ? Icons.wifi : Icons.wifi_off, color: _isConnected ? Colors.greenAccent : Colors.redAccent, size: 14),
                const SizedBox(width: 6),
                Text(_isConnected ? 'SYNCED' : 'OFFLINE', style: TextStyle(color: _isConnected ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Book Cover (Blurred)
          if (widget.book.coverUrl.isNotEmpty) ...[
            Image.network(
              widget.book.coverUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
          ] else ...[
            Container(color: const Color(0xFF0D0E15)),
          ],
          
          SafeArea(
            child: Column(
              children: [
                // Reading Area
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.book.coverUrl.isNotEmpty)
                          Hero(
                            tag: 'cover_${widget.book.title}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(widget.book.coverUrl, height: 200, fit: BoxFit.cover),
                            ).animate().fade().scale(delay: 200.ms),
                          ),
                        const SizedBox(height: 32),
                        Text(
                          'Page $_currentPage',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w200, color: Colors.white, letterSpacing: -2),
                        ).animate(key: ValueKey(_currentPage)).fadeIn().slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          '${((_currentPage / widget.book.pageCount) * 100).toStringAsFixed(1)}% Completed',
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 250,
                          child: LinearProgressIndicator(
                            value: _currentPage / widget.book.pageCount,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(10),
                          ).animate().scaleX(alignment: Alignment.centerLeft),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Notes Area (Glassmorphism List)
                Container(
                  height: 220,
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 16, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            const Icon(Icons.history_edu, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text('Ghost Mesh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Text('${_annotations.length} Peers Notes', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ...currentPageNotes.map((n) {
                              final decrypted = CryptoService.decryptPayload(n.encryptedPayload, widget.roomId, n.pageNumber);
                              return _buildNoteCard(false, decrypted ?? 'Decryption Failed', n.pageNumber);
                            }),
                            ...futureNotes.map((n) {
                              return _buildNoteCard(true, 'Encrypted Node', n.pageNumber);
                            }),
                            if (currentPageNotes.isEmpty && futureNotes.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text('No anomalies detected on this sync path.', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                                ),
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Controls Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _currentPage > 1 ? () {
                          setState(() => _currentPage--);
                          _loadAnnotations();
                        } : null,
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
                      ),
                      GestureDetector(
                        onTap: _showAddNoteDialog,
                        child: Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)]),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ).animate().scale(delay: 500.ms).shimmer(duration: 2.seconds, delay: 1.seconds),
                      ),
                      IconButton(
                        onPressed: _currentPage < widget.book.pageCount ? () {
                          setState(() => _currentPage++);
                          _loadAnnotations();
                        } : null,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(bool isLocked, String text, int page) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12, bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLocked ? Colors.black.withOpacity(0.4) : const Color(0xFF8B5CF6).withOpacity(0.2),
              border: Border.all(color: isLocked ? Colors.white.withOpacity(0.05) : const Color(0xFF8B5CF6).withOpacity(0.5)),
            ),
            child: Stack(
              children: [
                if (isLocked) ...[
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 36, color: Colors.white30).animate(onPlay: (c) => c.repeat(reverse:true)).shimmer(duration: 2.seconds),
                        const SizedBox(height: 8),
                        Text('Unlocks Pg $page', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                if (!isLocked) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF06B6D4), size: 14),
                          const SizedBox(width: 4),
                          Text('Page $page', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(curve: Curves.easeOutBack, delay: 100.ms);
  }

  @override
  void dispose() {
    _webRTCService.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
