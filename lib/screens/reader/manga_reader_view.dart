import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../services/storage_service.dart';
import '../../providers/providers.dart';

enum ReadMode { vertical, rtl, ltr }

class MangaReaderView extends ConsumerStatefulWidget {
  final String mangaId;
  final String title;
  final List<Map<String, String>> chapters;
  final int initialIndex;

  const MangaReaderView({
    super.key,
    required this.mangaId,
    required this.title,
    required this.chapters,
    required this.initialIndex,
  });

  @override
  ConsumerState<MangaReaderView> createState() => _MangaReaderViewState();
}

class _MangaReaderViewState extends ConsumerState<MangaReaderView> {
  late int _currentIndex;
  List<String> _pageUrls = [];
  bool _isLoading = true;
  bool _showUI = false;
  ReadMode _readMode = ReadMode.vertical;
  
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  bool _hasRestoredPosition = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchInitialChapter();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveScrollPosition();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_readMode != ReadMode.vertical) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 1500) {
      if (!_isLoading && _currentIndex < widget.chapters.length - 1) {
        _loadNextChapter();
      }
    }
  }

  void _onPageChanged(int index) {
    if (_readMode == ReadMode.vertical) return;
    if (!_isLoading && index >= _pageUrls.length - 2 && _currentIndex < widget.chapters.length - 1) {
      _loadNextChapter();
    }
  }

  Future<void> _saveScrollPosition() async {
    final key = StorageService.scrollPositionKey(widget.mangaId);
    if (_readMode == ReadMode.vertical) {
      if (_scrollController.hasClients) {
        await StorageService.write(key, _scrollController.offset.toString());
      }
    } else {
      if (_pageController.hasClients) {
        await StorageService.write(key, _pageController.page?.round().toString() ?? "0");
      }
    }
  }

  Future<void> _saveBookmark(String chapterNum) async {
    await ref.read(bookmarkProvider.notifier).saveBookmark(widget.mangaId, widget.title, chapterNum);
  }

  void _toggleReadMode() {
    HapticFeedback.lightImpact();
    _saveScrollPosition();
    setState(() {
      _readMode = ReadMode.values[(_readMode.index + 1) % ReadMode.values.length];
      _hasRestoredPosition = false;
    });
  }

  Future<void> _fetchInitialChapter() async {
    setState(() => _isLoading = true);
    final chapter = widget.chapters[_currentIndex];
    
    try {
      final pages = await ref.read(downloadServiceProvider).getChapterPages(
        widget.mangaId, 
        chapter['id']!,
        networkFallback: () => ref.read(mangaDexServiceProvider).fetchChapterPages(chapter['id']!),
      );

      if (mounted) {
        setState(() {
          _pageUrls = pages;
          _isLoading = false;
        });
        await _saveBookmark(chapter['number']!);
        _handleSafeJump();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load chapter'), backgroundColor: Colors.red));
      }
    }
  }

  void _handleSafeJump() async {
    if (_hasRestoredPosition) return;
    final key = StorageService.scrollPositionKey(widget.mangaId);
    final posStr = await StorageService.read(key);
    if (posStr != null && mounted) {
      final pos = double.tryParse(posStr) ?? 0;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (_readMode == ReadMode.vertical && _scrollController.hasClients) {
          final max = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(pos > max ? max : pos);
        } else if (_readMode != ReadMode.vertical && _pageController.hasClients) {
          int page = pos.toInt();
          if (page >= _pageUrls.length) page = _pageUrls.length - 1;
          _pageController.jumpToPage(page);
        }
      });
    }
    _hasRestoredPosition = true;
  }

  Future<void> _loadNextChapter() async {
    setState(() => _isLoading = true);
    _currentIndex++;
    final chapter = widget.chapters[_currentIndex];

    try {
      final pages = await ref.read(downloadServiceProvider).getChapterPages(
        widget.mangaId, 
        chapter['id']!,
        networkFallback: () => ref.read(mangaDexServiceProvider).fetchChapterPages(chapter['id']!),
      );

      if (mounted) {
        setState(() {
          _pageUrls.addAll(pages);
          _isLoading = false;
        });
        await _saveBookmark(chapter['number']!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentIndex--;
        });
      }
    }
  }

  Widget _buildPageItem(String path) {
    bool isNetwork = path.startsWith('http');
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: isNetwork
          ? Image.network(path, fit: BoxFit.contain, loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(color: AppColors.matchaGreen));
      })
          : Image.file(File(path), fit: BoxFit.contain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapters[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showUI = !_showUI),
            child: _isLoading && _pageUrls.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.matchaGreen))
                : _readMode == ReadMode.vertical
                ? ListView.builder(
              controller: _scrollController,
              itemCount: _pageUrls.length + (_isLoading ? 1 : 0),
              cacheExtent: 99999,
              itemBuilder: (context, index) {
                if (index == _pageUrls.length) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.matchaGreen)));
                return _buildPageItem(_pageUrls[index]);
              },
            )
                : PageView.builder(
              controller: _pageController,
              reverse: _readMode == ReadMode.rtl,
              itemCount: _pageUrls.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _buildPageItem(_pageUrls[index]),
            ),
          ),
          if (_showUI)
            Positioned(
              top: 0, left: 0, right: 0,
              child: AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.8),
                elevation: 0,
                leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Chapter ${chapter["number"]}', style: const TextStyle(fontSize: 12, color: AppColors.matchaGreen)),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(_readMode == ReadMode.vertical ? Icons.swap_vert : _readMode == ReadMode.rtl ? Icons.format_textdirection_r_to_l : Icons.format_textdirection_l_to_r, color: Colors.white),
                    onPressed: _toggleReadMode,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
