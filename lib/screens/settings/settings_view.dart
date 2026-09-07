import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isLoading = true;
  String _cacheSize = "0.00 MB";

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    setState(() => _isLoading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      double totalSize = 0;

      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }

      setState(() {
        _cacheSize = "${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _cacheSize = "Error reading storage";
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((entity) {
          if (entity is File) {
            entity.deleteSync();
          }
        });
      }

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // NOTE: We intentionally do NOT call secureStorage.deleteAll()
      // to preserve user's favorites, history, and repos.

      await _calculateCacheSize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache cleared! Your data is safe.'),
              backgroundColor: AppColors.matchaGreen,
              behavior: SnackBarBehavior.floating,
            )
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkForest)),
            const SizedBox(height: 30),

            const Text('Storage & Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.softMintBg, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.softMintBg, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.sd_storage_rounded, color: AppColors.matchaGreen),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Image Cache', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkForest)),
                            const SizedBox(height: 4),
                            Text(
                                'Temporary images taking up space.',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13)
                            ),
                          ],
                        ),
                      ),
                      _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.matchaGreen))
                          : Text(_cacheSize, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.matchaGreen)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFECEC),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _clearCache,
                      child: const Text('Clear Cache', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text('About Matcha Reader', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.matchaGreen),
              title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkForest)),
              trailing: const Text('1.0.0 Pro', style: TextStyle(color: AppColors.mutedSage, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code_rounded, color: AppColors.matchaGreen),
              title: const Text('Lead Developer', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkForest)),
              trailing: const Text('Jhervin Jimenez', style: TextStyle(color: AppColors.mutedSage, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
