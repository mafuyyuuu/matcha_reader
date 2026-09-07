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
  
  bool _isLoading = false;

  Future<void> _installRepo(Map<String, dynamic> repoInfo) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(extensionsProvider.notifier).addRepo(repoInfo);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Installed ${repoInfo["name"]}!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Install failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _uninstallRepo(String url) {
    ref.read(extensionsProvider.notifier).removeRepo(url);
  }

  Widget _buildStoreTab() {
    final storeAsync = ref.watch(extensionStoreProvider);

    return storeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.matchaGreen)),
      error: (err, stack) => Center(child: Text('Failed to load store: $err', style: const TextStyle(color: Colors.red))),
      data: (storeRepos) {
        if (storeRepos.isEmpty) {
          return const Center(child: Text('No extensions available in the global store.', style: TextStyle(color: AppColors.mutedSage)));
        }
        
        final installedRepos = ref.watch(extensionsProvider);
        
        return ListView.builder(
          itemCount: storeRepos.length,
          itemBuilder: (context, index) {
            final repo = storeRepos[index];
            final isInstalled = installedRepos.any((r) => r['name'] == repo['name']);

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
                      Text(isInstalled ? "Installed" : "Available", style: TextStyle(color: isInstalled ? AppColors.matchaGreen : AppColors.sageText, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  _isLoading && !isInstalled
                      ? const CircularProgressIndicator(color: AppColors.matchaGreen)
                      : ElevatedButton(
                          onPressed: isInstalled ? () => _uninstallRepo(repo['name']) : () => _installRepo(repo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInstalled ? Colors.redAccent : AppColors.matchaGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isInstalled ? 'Uninstall' : 'Install'),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Extension Store', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkForest)),
            const SizedBox(height: 10),
            const Text('Install community repositories to read from your favorite sources.', style: TextStyle(color: AppColors.sageText)),
            const SizedBox(height: 30),
            Expanded(child: _buildStoreTab()),
          ],
        ),
      ),
    );
  }
}
