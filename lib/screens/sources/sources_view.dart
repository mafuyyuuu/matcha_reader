import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class SourcesView extends ConsumerStatefulWidget {
  const SourcesView({super.key});

  @override
  ConsumerState<SourcesView> createState() => _SourcesViewState();
}

class _SourcesViewState extends ConsumerState<SourcesView> {
  final TextEditingController _repoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addRepo(String url) async {
    if (url.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final extService = ref.read(extensionServiceProvider);
      String repoName = url;
      String repoType = url.endsWith('.json') ? 'json' : 'js';

      if (repoType == 'js') {
        final info = await extService.getExtensionInfo(url);
        repoName = info['name'] ?? repoName;
      }

      await ref.read(extensionsProvider.notifier).addRepo({
        'url': url.trim(),
        'name': repoName,
        'type': repoType
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _repoController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Installed $repoName!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid repository: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _removeRepo(String url) {
    ref.read(extensionsProvider.notifier).removeRepo(url);
  }

  @override
  Widget build(BuildContext context) {
    final installedRepos = ref.watch(extensionsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Extensions', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkForest)),
            const SizedBox(height: 10),
            const Text('Add third-party JSON or JS repositories to search across multiple sources seamlessly.', style: TextStyle(color: AppColors.sageText)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.softMintBg, width: 2)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _repoController,
                      decoration: const InputDecoration(hintText: 'https://example.com/extension.js', hintStyle: TextStyle(color: AppColors.mutedSage, fontSize: 14), border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.matchaGreen, strokeWidth: 2))
                      : GestureDetector(
                    onTap: () => _addRepo(_repoController.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.matchaGreen, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('Installed Sources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
            const SizedBox(height: 16),
            Expanded(
              child: installedRepos.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.extension_off_rounded, size: 48, color: AppColors.mutedSage.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text('No extensions installed.', style: TextStyle(color: AppColors.mutedSage)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: installedRepos.length,
                itemBuilder: (context, index) {
                  final repo = installedRepos[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.softMintBg, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(repo['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkForest, fontSize: 16)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: repo['type'] == 'json' ? Colors.blue : Colors.orange, borderRadius: BorderRadius.circular(6)),
                                  child: Text(repo['type'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(width: MediaQuery.of(context).size.width - 150, child: Text(repo['url'], style: const TextStyle(color: AppColors.sageText, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _removeRepo(repo['url'])),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
