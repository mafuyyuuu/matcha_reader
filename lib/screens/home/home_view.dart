import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../models/manga.dart';
import '../../services/storage_service.dart';
import '../../providers/providers.dart';
import '../search/search_results_view.dart';
import '../details/manga_details_view.dart';
import 'widgets/manga_card.dart';
import 'widgets/ai_curated_card.dart';
import 'dart:convert';

class HomeView extends ConsumerStatefulWidget {
  final List<Manga> mangaList;
  final bool isLoading;

  const HomeView({super.key, required this.mangaList, required this.isLoading});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  List<String> _filteredSearches = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSearchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSearches = _recentSearches;
      } else {
        _filteredSearches = _recentSearches.where((s) => s.toLowerCase().contains(query)).toList();
      }
    });
  }

  Future<void> _loadSearchData() async {
    final String? recentJson = await StorageService.read('recent_searches');
    List<String> recents = [];
    if (recentJson != null) {
      recents = List<String>.from(jsonDecode(recentJson));
    }

    setState(() {
      _recentSearches = recents;
      _filteredSearches = recents;
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    List<String> recents = List.from(_recentSearches);
    recents.remove(query);
    recents.insert(0, query);
    if (recents.length > 10) recents = recents.sublist(0, 10);
    
    await StorageService.write('recent_searches', jsonEncode(recents));
    setState(() {
      _recentSearches = recents;
      _onSearchChanged();
    });
  }

  Future<void> _clearRecentSearches() async {
    await StorageService.delete('recent_searches');
    setState(() {
       _recentSearches = [];
       _filteredSearches = [];
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    _saveRecentSearch(query.trim());
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = false);
    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultsView(query: query.trim())));
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final bookmark = ref.watch(bookmarkProvider);
    final lastReadId = bookmark['id'];
    final lastReadTitle = bookmark['title'];
    final lastReadChapter = bookmark['chapter'];
    final lastReadSource = bookmark['source'] ?? 'MangaDex';

    return SafeArea(
      child: GestureDetector(
        onTap: () {
           FocusScope.of(context).unfocus();
           setState(() => _isSearching = false);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getGreeting(), style: const TextStyle(color: AppColors.mutedSage, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Jhervin Jimenez', style: TextStyle(color: AppColors.darkForest, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: AppColors.softMintBg, borderRadius: BorderRadius.circular(15)),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onTap: () => setState(() => _isSearching = true),
                        onSubmitted: _submitSearch,
                        decoration: const InputDecoration(
                          hintText: 'Search your favorite manhwa...',
                          hintStyle: TextStyle(color: AppColors.mutedSage, fontSize: 14, fontWeight: FontWeight.w500),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: AppColors.matchaGreen, size: 22),
                        ),
                      ),
                    ),

                    if (_isSearching && _filteredSearches.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Recent Searches", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedSage)),
                                  GestureDetector(
                                    onTap: _clearRecentSearches,
                                    child: const Text("Clear", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            ),
                            ..._filteredSearches.map((query) => ListTile(
                              leading: const Icon(Icons.history, color: AppColors.mutedSage, size: 20),
                              title: Text(query, style: const TextStyle(fontSize: 14, color: AppColors.sageText)),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              onTap: () {
                                _searchController.text = query;
                                _submitSearch(query);
                              },
                            )),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Continue Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkForest)),
            ),
            const SizedBox(height: 16),

            lastReadId != null
                ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MangaDetailsView(
                        mangaId: lastReadId,
                        title: lastReadTitle ?? "Unknown",
                        imageUrl: ApiConstants.fallbackImageUrl,
                        resumeChapterNum: lastReadChapter,
                        source: lastReadSource,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.matchaGreen, width: 1.5),
                    boxShadow: [BoxShadow(color: AppColors.matchaGreen.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppColors.matchaGreen, size: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lastReadTitle ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.darkForest), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('Resume Chapter $lastReadChapter', style: const TextStyle(color: AppColors.matchaGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_circle_fill_rounded, color: AppColors.matchaGreen, size: 35),
                    ],
                  ),
                ),
              ),
            )
                : const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Read a manga to see your progress here!", style: TextStyle(color: AppColors.mutedSage, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 30),

            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Trending Right Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkForest))
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.matchaGreen))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.mangaList.length,
                itemBuilder: (context, index) {
                  final manga = widget.mangaList[index];
                  return MangaCard(
                    mangaId: manga.id,
                    title: manga.title,
                    chapter: 'New',
                    progress: 0.0,
                    imageUrl: manga.imageUrl,
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Curated by AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkForest))),
            const SizedBox(height: 16),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: AICuratedCard()),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }
}
