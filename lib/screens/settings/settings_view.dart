import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/storage_service.dart';
import '../../providers/providers.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  String _cacheSize = "Calculating...";

  @override
  void initState() {
    super.initState();
    _calculateCache();
  }

  Future<void> _calculateCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      if (mounted) {
        setState(() {
          _cacheSize = "${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cacheSize = "Unknown");
    }
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will delete all temporary images and files. Your favorites and downloads will remain safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.mutedSage))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _cacheSize = "Clearing...");
              try {
                final tempDir = await getTemporaryDirectory();
                if (tempDir.existsSync()) {
                  tempDir.listSync(recursive: true, followLinks: false).forEach((entity) {
                    if (entity is File) entity.deleteSync();
                  });
                }
                await _calculateCache();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully'), backgroundColor: Colors.green));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to clear cache'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _wipeData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe All Data?', style: TextStyle(color: Colors.redAccent)),
        content: const Text('This will permanently delete your favorites, reading history, downloaded chapters, and bookmarks. This cannot be undone.', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.mutedSage))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.deleteAll();
              final dir = await getApplicationDocumentsDirectory();
              final downloadDir = Directory('${dir.path}/downloads');
              if (downloadDir.existsSync()) downloadDir.deleteSync(recursive: true);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data wiped. Please restart the app.'), backgroundColor: Colors.red));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('WIPE EVERYTHING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkForest)),
            const SizedBox(height: 30),
            
            const Text('Library', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.softMintBg, width: 2)),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.matchaGreen,
                title: const Text('Auto-Update Library', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkForest)),
                subtitle: const Text('Check for new chapters automatically when the app launches.', style: TextStyle(fontSize: 12, color: AppColors.mutedSage)),
                value: settings['autoUpdateLibrary'] ?? false,
                onChanged: (val) {
                  ref.read(appSettingsProvider.notifier).toggleAutoUpdate(val);
                },
              ),
            ),
            const SizedBox(height: 30),

            const Text('Data & Storage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.softMintBg, width: 2)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.matchaGreen),
                    title: const Text('Clear Image Cache', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkForest)),
                    subtitle: Text(_cacheSize, style: const TextStyle(color: AppColors.mutedSage)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.mutedSage),
                    onTap: _clearCache,
                  ),
                  const Divider(height: 1, color: AppColors.softMintBg),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    title: const Text('Wipe All App Data', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    subtitle: const Text('Irreversible action', style: TextStyle(color: AppColors.mutedSage)),
                    onTap: _wipeData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.energy_savings_leaf, size: 40, color: AppColors.matchaGreen.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  const Text('Matcha Reader Pro', style: TextStyle(color: AppColors.darkForest, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Version 2.0.0', style: TextStyle(color: AppColors.mutedSage, fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('Built with Flutter ❤️', style: TextStyle(color: AppColors.mutedSage, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
