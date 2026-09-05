import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/providers.dart';
import '../details/manga_details_view.dart';

class LibraryView extends ConsumerWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final favorites = ref.watch(favoritesProvider);
    final bookmark = ref.watch(bookmarkProvider);

    final lastReadId = bookmark['id'];
    final lastReadTitle = bookmark['title'];
    final lastReadChapter = bookmark['chapter'];

    return SafeArea(
      child: CustomScrollView(
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
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MangaDetailsView(mangaId: item['id'], title: item['title'], imageUrl: item['imageUrl'])));
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
                      ? _buildBookmarkCard(context, lastReadId, lastReadTitle!, lastReadChapter!)
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
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MangaDetailsView(mangaId: fav['id'], title: fav['title'], imageUrl: fav['imageUrl'])),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppColors.softMintBg),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Hero(
                          tag: 'cover_${fav["id"]}',
                          child: Image.network(fav['imageUrl'], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  );
                },
                childCount: favorites.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context, String lastReadId, String lastReadTitle, String lastReadChapter) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => MangaDetailsView(mangaId: lastReadId, title: lastReadTitle, imageUrl: ApiConstants.fallbackImageUrl, resumeChapterNum: lastReadChapter)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.softMintBg, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
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
