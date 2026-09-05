import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/theme/app_colors.dart';
import '../../services/storage_service.dart';

class SourcesView extends StatefulWidget {
  const SourcesView({super.key});

  @override
  State<SourcesView> createState() => _SourcesViewState();
}

class _SourcesViewState extends State<SourcesView> {
  final TextEditingController _repoController = TextEditingController();
  List<Map<String, dynamic>> _installedRepos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    final String? reposJson = await StorageService.read('user_repos');
    if (reposJson != null) {
      final List<dynamic> decoded = jsonDecode(reposJson);
      if (decoded.isNotEmpty && decoded.first is String) {
        await StorageService.delete('user_repos');
      } else {
        setState(() {
          _installedRepos = decoded.cast<Map<String, dynamic>>();
        });
      }
    }
  }

  Future<void> _addRepo(String url) async {
    if (url.trim().isEmpty) return;

    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid URL starting with http/https'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception("Could not reach repository");

      String repoName = "Community Extension";
      String repoType = "js";

      bool isJson = false;
      try {
        final parsedJson = jsonDecode(response.body);
        if (parsedJson is Map && parsedJson.containsKey('selectors')) {
           isJson = true;
           repoType = "json";
           repoName = parsedJson['name'] ?? "JSON Extension";
        }
      } catch (e) {
      }

      if (!isJson) {
        final completer = Completer<String?>();
        HeadlessInAppWebView? headlessWebView;

        headlessWebView = HeadlessInAppWebView(
          initialData: InAppWebViewInitialData(data: """
            <!DOCTYPE html>
            <html>
            <head>
              <script>
                ${response.body}
              </script>
            </head>
            <body></body>
            </html>
          """),
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(handlerName: 'nativeFetch', callback: (args) async {
              try {
                final res = await http.get(Uri.parse(args[0]));
                return res.body;
              } catch (e) {
                return "ERROR: $e";
              }
            });
          },
          onLoadStop: (controller, url) async {
            try {
              await controller.evaluateJavascript(source: """
                window.fetch = async (url) => {
                  const body = await window.flutter_inappwebview.callHandler('nativeFetch', url);
                  return { text: async () => body, ok: true };
                };
              """);
              final result = await controller.evaluateJavascript(source: "typeof getExtensionInfo === 'function' ? JSON.stringify(getExtensionInfo()) : null");
              completer.complete(result?.toString());
            } catch (e) {
              if (!completer.isCompleted) completer.completeError(e);
            }
          },
          onLoadError: (controller, url, code, message) {
            if (!completer.isCompleted) completer.completeError(message);
          }
        );

        await headlessWebView.run();

        try {
          final infoResult = await completer.future.timeout(const Duration(seconds: 5));
          if (infoResult != null && infoResult != 'null') {
             final info = jsonDecode(infoResult);
             repoName = info['name'] ?? repoName;
          }
        } catch (e) {
           await headlessWebView.dispose();
           throw Exception("Invalid Javascript or Timeout: $e");
        }
        
        await headlessWebView.dispose();
      }

      final String? reposJson = await StorageService.read('user_repos');      
      List<dynamic> currentRepos = reposJson != null ? jsonDecode(reposJson) : [];

      if (!currentRepos.any((repo) => repo['url'] == url)) {
        currentRepos.add({'url': url.trim(), 'name': repoName, 'type': repoType});
        await StorageService.write('user_repos', jsonEncode(currentRepos));

        setState(() {
          _installedRepos = currentRepos.cast<Map<String, dynamic>>();
          _isLoading = false;
          _repoController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Installed $repoName!'), backgroundColor: Colors.green));
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repository already exists.'), backgroundColor: Colors.orange));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Validation Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _removeRepo(String url) async {
    final String? reposJson = await StorageService.read('user_repos');
    if (reposJson != null) {
      List<dynamic> currentRepos = jsonDecode(reposJson);
      currentRepos.removeWhere((repo) => repo['url'] == url);
      await StorageService.write('user_repos', jsonEncode(currentRepos));

      setState(() {
        _installedRepos = currentRepos.cast<Map<String, dynamic>>();
      });
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
            const Text('Sources', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkForest)),
            const SizedBox(height: 8),
            const Text('Add community repositories to expand your catalog.', style: TextStyle(color: AppColors.mutedSage, fontSize: 14)),
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.softMintBg, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: AppColors.matchaGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repoController,
                      decoration: const InputDecoration(
                        hintText: 'Paste repository URL...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.mutedSage),
                      ),
                      onSubmitted: _addRepo,
                    ),
                  ),
                  _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.matchaGreen))
                      : IconButton(
                    icon: const Icon(Icons.add_circle_rounded, color: AppColors.matchaGreen),
                    onPressed: () => _addRepo(_repoController.text),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Text('Installed Extensions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.sageText)),
            const SizedBox(height: 16),

            Expanded(
              child: _installedRepos.isEmpty
                  ? const Center(
                  child: Text(
                      "No extensions installed.\nAdd a repository URL to get started.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedSage, height: 1.5)
                  )
              )
                  : ListView.builder(
                itemCount: _installedRepos.length,
                itemBuilder: (context, index) {
                  final repo = _installedRepos[index];
                  final url = repo['url'];
                  final name = repo['name'] ?? 'Community Repository';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.softMintBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.matchaGreen, child: Icon(Icons.extension_rounded, color: Colors.white, size: 18)),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkForest), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(url, style: const TextStyle(color: AppColors.mutedSage, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () => _removeRepo(url),
                      ),
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
