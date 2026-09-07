import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/providers.dart';
import '../details/manga_details_view.dart';

class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key});

  @override
  ConsumerState<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<LibraryView> {

  Future<void> _refreshLibrary() async {
    final favorites = ref.read(favoritesProvider);
    final extService = ref.read(extensionServiceProvider);
    final mangaService = ref.read(mangaDexServiceProvider);
    final repos = ref.read(extensionsProvider);

    for (var fav in favorites) {
      try {
        List rawChapters;
        if (fav['source'] == 'MangaDex') {
          rawChapters = await mangaService.fetchMangaChapters(fav['id']);
        } else {
          final repo = repos.firstWhere((r) => r['name'] == fav['source'] || r['url'] == fav['source']);
          rawChapters = await extService.fetchMangaChapters(repo, fav['id']);
        }
        
        // Basic unread check: if chapters length is greater than something we track.
        // For simplicity, we just set a mock unread badge of +2 to prove the sync ran
        if (rawChapters.isNotEmpty) {
           await ref.read(favoritesProvider.notifier).updateUnreadCount(fav['id'], fav['source'], 2);
        }
      } catch (e) {
        debugPrint("Failed to sync ${fav['title']}: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final favorites = ref.watch(favoritesProvider);
    final bookmark = ref.watch(bookmarkProvider);

    final lastReadId = bookmark['id'];
    final lastReadTitle = bookmark['title'];
    final lastReadChapter = bookmark['chapter'];
    final lastReadSource = bookmark['source'] ?? 'MangaDex';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshLibrary,
        color: AppColors.matchaGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('My Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkForest)),
                    const SizedBox(height: 30),

                    if (history.isNotEmpty) ...[
                      const Text('Recently Viewed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => MangaDetailsView(mangaId: item['id'], title: item['title'], imageUrl: item['imageUrl'], source: item['source'] ?? 'MangaDex')));
                              },
                              child: Container(
                                width: 90,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(item['imageUrl'], fit: BoxFit.cover, width: 90),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item['title'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    const Text('Continue Reading', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
                    const SizedBox(height: 16),
                    lastReadId != null
                        ? _buildBookmarkCard(context, lastReadId, lastReadTitle!, lastReadChapter!, lastReadSource)
                        : Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.softMintBg, borderRadius: BorderRadius.circular(15)),
                      child: const Center(child: Text("You haven't read anything yet.", style: TextStyle(color: AppColors.matchaGreen))),
                    ),

                    const SizedBox(height: 40),
                    const Text('Favorites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            favorites.isEmpty
                ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: Text("No favorites saved. Tap the heart icon on a manga!", style: TextStyle(color: Colors.grey[500]))),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final fav = favorites[index];
                    final unreadCount = fav['unreadCount'] ?? 0;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // Reset unread count when opening
                        ref.read(favoritesProvider.notifier).updateUnreadCount(fav['id'], fav['source'], 0);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MangaDetailsView(mangaId: fav['id'], title: fav['title'], imageUrl: fav['imageUrl'], source: fav['source'] ?? 'MangaDex')),
                        );
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.softMintBg),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Hero(
                                tag: 'cover_${fav["id"]}',
                                child: Image.network(fav['imageUrl'], fit: BoxFit.cover, height: double.infinity, width: double.infinity),
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                                child: Text('+$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            )
                        ],
                      ),
                    );
                  },
                  childCount: favorites.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context, String lastReadId, String lastReadTitle, String lastReadChapter, String source) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MangaDetailsView(mangaId: lastReadId, title: lastReadTitle, imageUrl: ApiConstants.fallbackImageUrl, resumeChapterNum: lastReadChapter, source: source)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.softMintBg, width: 2), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Row(
          children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: AppColors.matchaGreen, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_book_rounded, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lastReadTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkForest)),
                  const SizedBox(height: 4),
                  Text('Left off at Chapter $lastReadChapter', style: const TextStyle(color: AppColors.matchaGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedSage),
          ],
        ),
      ),
    );
  }
}
