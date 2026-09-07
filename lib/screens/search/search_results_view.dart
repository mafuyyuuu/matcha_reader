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
  Map<String, List<Manga>> _groupedResults = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performConcurrentSearch();
  }

  Future<void> _performConcurrentSearch() async {
    final mangaDexService = ref.read(mangaDexServiceProvider);
    final extService = ref.read(extensionServiceProvider);
    final repos = ref.read(extensionsProvider);

    Map<String, List<Manga>> tempGrouped = {};

    // Create a list of Futures
    List<Future<void>> searchTasks = [];

    // MangaDex Task
    searchTasks.add(
      mangaDexService.searchManga(widget.query).then((results) {
        if (results.isNotEmpty) tempGrouped['MangaDex'] = results;
      }).catchError((e) {
        debugPrint("MangaDex search failed: $e");
      })
    );

    // Extension Tasks
    for (var repo in repos) {
      searchTasks.add(
        extService.searchManga(repo, widget.query).then((results) {
          if (results.isNotEmpty) tempGrouped[repo['name']] = results;
        }).catchError((e) {
          debugPrint("Extension search failed for ${repo['name']}: $e");
        })
      );
    }

    // Wait for all to finish concurrently
    await Future.wait(searchTasks);

    if (mounted) {
      setState(() {
        _groupedResults = tempGrouped;
        _isLoading = false;
      });
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
          : _groupedResults.isEmpty
          ? const Center(child: Text("No manga found across any source.", style: TextStyle(color: AppColors.mutedSage)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _groupedResults.keys.length,
              itemBuilder: (context, index) {
                String sourceName = _groupedResults.keys.elementAt(index);
                List<Manga> sourceResults = _groupedResults[sourceName]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sourceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkForest)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sourceResults.length,
                        itemBuilder: (context, idx) {
                          final manga = sourceResults[idx];
                          return MangaCard(
                            mangaId: manga.id,
                            title: manga.title,
                            chapter: manga.source, 
                            progress: 0.0,
                            imageUrl: manga.imageUrl,
                            isUniversal: true,
                            source: manga.source,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
    );
  }
}
