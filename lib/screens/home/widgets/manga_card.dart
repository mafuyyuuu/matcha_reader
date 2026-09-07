import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../details/manga_details_view.dart';

class MangaCard extends StatelessWidget {
  final String mangaId;
  final String title;
  final String chapter;
  final double progress;
  final String imageUrl;
  final String source;
  final bool isUniversal;

  const MangaCard({
    super.key,
    required this.mangaId,
    required this.title,
    required this.chapter,
    required this.progress,
    required this.imageUrl,
    this.source = 'MangaDex',
    this.isUniversal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailsView(
                mangaId: mangaId,
                title: title,
                imageUrl: imageUrl,
                source: source,
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.softMintBg, borderRadius: BorderRadius.circular(14)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Hero(
                  tag: 'cover_$mangaId',
                  child: Image.network(
                    imageUrl, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: AppColors.matchaGreen)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(isUniversal ? source : 'Chapter $chapter', style: TextStyle(color: isUniversal ? Colors.blue : AppColors.mutedSage, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            if (!isUniversal)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: progress, backgroundColor: AppColors.softMintBg, color: AppColors.matchaGreen, minHeight: 6),
              ),
          ],
        ),
      ),
    );
  }
}
