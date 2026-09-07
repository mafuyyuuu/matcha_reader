import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../reader/manga_reader_view.dart';

class MangaDetailsView extends ConsumerStatefulWidget {
  final String mangaId;
  final String title;
  final String imageUrl;
  final String? resumeChapterNum;
  final String source;

  const MangaDetailsView({
    super.key,
    required this.mangaId,
    required this.title,
    required this.imageUrl,
    this.resumeChapterNum,
    this.source = 'MangaDex',
  });

  @override
  ConsumerState<MangaDetailsView> createState() => _MangaDetailsViewState();
}

class _MangaDetailsViewState extends ConsumerState<MangaDetailsView> {
  bool _isLoading = true;
  String _description = "";
  String _author = "Unknown";
  String _status = "Unknown";
  String _year = "N/A";
  List<Map<String, String>> _chapters = [];
  Set<String> _downloadedChapters = {};

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    Future.microtask(() {
      ref.read(historyProvider.notifier).addToHistory(widget.mangaId, widget.title, widget.imageUrl, source: widget.source);
    });
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    await ref.read(favoritesProvider.notifier).toggleFavorite(widget.mangaId, widget.title, widget.imageUrl, source: widget.source);
  }

  Future<void> _checkDownloadedChapters(List<Map<String, String>> chapters) async {
    final ids = chapters.map((c) => c["id"]!).toList();
    final downloaded = await ref.read(downloadServiceProvider).getDownloadedChapterIds("${widget.source}_${widget.mangaId}", ids);
    if (mounted) setState(() => _downloadedChapters = downloaded);
  }

  Future<void> _downloadChapter(String chapterId, String chapterNum) async {
    if (widget.source != 'MangaDex') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading from extensions is not yet supported.')));
      return;
    }
    if (_downloadedChapters.contains(chapterId)) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading Chapter $chapterNum...'), backgroundColor: AppColors.matchaGreen));
    try {
      await ref.read(downloadServiceProvider).downloadChapter("${widget.source}_${widget.mangaId}", chapterId);
      if (mounted) {
        setState(() => _downloadedChapters.add(chapterId));
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chapter $chapterNum Downloaded!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _fetchDetails() async {
    try {
      Map<String, dynamic> details;
      List<Map<String, String>> uniqueList = [];

      if (widget.source == 'MangaDex') {
        final mangaService = ref.read(mangaDexServiceProvider);
        details = await mangaService.fetchMangaDetails(widget.mangaId);
        final rawChapters = await mangaService.fetchMangaChapters(widget.mangaId);
        uniqueList = rawChapters.map((c) => {'id': c.id, 'number': c.number, 'date': c.date}).toList();
      } else {
        // UNIVERSAL ROUTING
        final extService = ref.read(extensionServiceProvider);
        final repos = ref.read(extensionsProvider);
        final repo = repos.firstWhere((r) => r['name'] == widget.source || r['url'] == widget.source);
        
        details = await extService.fetchMangaDetails(repo, widget.mangaId);
        final rawChapters = await extService.fetchMangaChapters(repo, widget.mangaId);
        uniqueList = rawChapters.map((c) => {'id': c.id, 'number': c.number, 'date': c.date}).toList();
      }

      if (mounted) {
        setState(() {
          _description = details['description'] ?? "No description available.";
          _author = details['author'] ?? "Unknown";
          _status = details['status'] ?? "Unknown";
          _year = details['year']?.toString() ?? "N/A";
          _chapters = uniqueList;
          _isLoading = false;
        });
      }
      
      await _checkDownloadedChapters(uniqueList);
      
      if (widget.resumeChapterNum != null) {
        int targetIndex = uniqueList.indexWhere((c) => c['number'] == widget.resumeChapterNum);
        if (targetIndex != -1) {
          Future.microtask(() {
            if (mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MangaReaderView(mangaId: widget.mangaId, title: widget.title, chapters: uniqueList, initialIndex: targetIndex, source: widget.source)));
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Details Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.chipBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.matchaGreen),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color ?? AppColors.sageText)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorited = favorites.any((fav) => fav['id'] == widget.mangaId && fav['source'] == widget.source);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: isFavorited ? AppColors.matchaGreen : Colors.white,
        onPressed: _toggleFavorite,
        child: Icon(isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavorited ? Colors.white : AppColors.matchaGreen),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.matchaGreen))
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400, pinned: true,
            flexibleSpace: FlexibleSpaceBar(background: Hero(tag: 'cover_${widget.mangaId}', child: Image.network(widget.imageUrl, fit: BoxFit.cover))),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.darkForest, letterSpacing: -0.5))),
                      if (widget.source != 'MangaDex')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.source, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(Icons.person, _author),
                      _buildInfoChip(Icons.calendar_today, _year),
                      _buildInfoChip(Icons.info_outline, _status, color: _status == 'ONGOING' ? Colors.green : Colors.blue),
                      _buildInfoChip(Icons.list, "${_chapters.length} Chapters"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkForest)),
                  const SizedBox(height: 8),
                  Text(_description, style: const TextStyle(fontSize: 15, color: AppColors.sageText, height: 1.6)),
                  const SizedBox(height: 32),
                  const Text("Chapters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.darkForest)),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final chapter = _chapters[index];
                final isDownloaded = _downloadedChapters.contains(chapter['id']);
                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MangaReaderView(mangaId: widget.mangaId, title: widget.title, chapters: _chapters, initialIndex: index, source: widget.source)));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.softMintBg))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Chapter ${chapter["number"]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkForest)),
                            const SizedBox(height: 4),
                            Text(chapter['date'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.mutedSage)),
                          ],
                        ),
                        if (widget.source == 'MangaDex')
                          Row(
                            children: [
                              if (isDownloaded) const Icon(Icons.check_circle_rounded, color: AppColors.matchaGreen, size: 20),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(Icons.download_rounded, color: isDownloaded ? AppColors.mutedSage : AppColors.matchaGreen),
                                onPressed: () => _downloadChapter(chapter['id']!, chapter['number']!),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                );
              },
              childCount: _chapters.length,
            ),
          ),
        ],
      ),
    );
  }
}
