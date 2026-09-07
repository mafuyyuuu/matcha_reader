import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/manga.dart';
import '../../providers/providers.dart';
import '../home/widgets/manga_card.dart';

class SearchResultsView extends ConsumerStatefulWidget {
  final String query;
  const SearchResultsView({super.key, required this.query});

  @override
  ConsumerState<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends ConsumerState<SearchResultsView> {
  List<Manga> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    try {
      final mangaDexService = ref.read(mangaDexServiceProvider);
      final extService = ref.read(extensionServiceProvider);
      
      // MangaDex Search
      List<Manga> tempResults = await mangaDexService.searchManga(widget.query);

      // Extensions Search
      final repos = ref.read(extensionsProvider);
      for (var repo in repos) {
        try {
          final extManga = await extService.searchManga(repo, widget.query);
          tempResults.insertAll(0, extManga); // Prioritize extension results
        } catch (e) {
          debugPrint("Extension search failed for ${repo['name']}: $e");
        }
      }

      if (mounted) {
        setState(() {
          _results = tempResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkForest),
        title: Text('Search: "${widget.query}"', style: const TextStyle(color: AppColors.darkForest, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.matchaGreen))
          : _results.isEmpty
          ? const Center(child: Text("No manga found. Try another title!", style: TextStyle(color: AppColors.mutedSage)))
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final manga = _results[index];
          return MangaCard(
            mangaId: manga.id,
            title: manga.title,
            chapter: manga.source, // Show source instead of chapter for search results
            progress: 0.0,
            imageUrl: manga.imageUrl,
            isUniversal: true, // We will update MangaCard later or just pass source
          );
        },
      ),
    );
  }
}
