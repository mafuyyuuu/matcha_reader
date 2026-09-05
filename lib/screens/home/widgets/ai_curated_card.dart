import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AICuratedCard extends StatelessWidget {
  const AICuratedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.softMintBg, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/en/5/5a/The_Beginning_After_The_End_Volume_1.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.auto_awesome, color: AppColors.matchaGreen));
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.matchaGreen, borderRadius: BorderRadius.circular(12)),
                    child: const Text('98% MATCH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Beginning After The End', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkForest)),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: AppColors.sageText, fontSize: 13, height: 1.4),
                    children: [
                      TextSpan(text: 'Based on your love for '),
                      TextSpan(text: 'Solo Leveling', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkForest)),
                      TextSpan(text: ', try this reincarnation journey.'),
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
}
