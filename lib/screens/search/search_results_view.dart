import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as html_parser;
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../models/manga.dart';
import '../../services/storage_service.dart';
import '../details/manga_details_view.dart';

class SearchResultsView extends StatefulWidget {
  final String query;
  const SearchResultsView({super.key, required this.query});

  @override
  State<SearchResultsView> createState() => _SearchResultsViewState();
}

class _SearchResultsViewState extends State<SearchResultsView> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Manga> _results = [];
  int _offset = 0;
  final int _limit = 15;
  final ScrollController _scrollController = ScrollController();
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMoreData) {
        _performSearch(isLoadMore: true);
      }
    }
  }

  Future<List<Manga>> _searchExtension(Map<String, dynamic> repo, String query) async {
    List<Manga> extensionResults = [];
    final repoUrl = repo['url'] as String;
    final repoType = repo['type'] as String? ?? 'js';

    try {
      final response = await http.get(Uri.parse(repoUrl));
      if (response.statusCode != 200) return [];

      if (repoType == 'json') {
        final parsedJson = jsonDecode(response.body);
        final searchUrlTemplate = parsedJson['search_url'] as String?;
        final selectors = parsedJson['selectors'] as Map<String, dynamic>?;

        if (searchUrlTemplate != null && selectors != null) {
           final targetUrl = searchUrlTemplate.replaceAll('{query}', Uri.encodeComponent(query));
           final htmlResponse = await http.get(Uri.parse(targetUrl));
           
           if (htmlResponse.statusCode == 200) {
              var document = html_parser.parse(htmlResponse.body);
              var resultNodes = document.querySelectorAll(selectors['search_results'] ?? '');

              for (var node in resultNodes) {
                var titleNode = node.querySelector(selectors['title'] ?? '');
                var imageNode = node.querySelector(selectors['image'] ?? '');
                
                String title = titleNode?.text.trim() ?? 'Unknown Title';
                String imageUrl = '';
                if (imageNode != null) {
                  String attr = selectors['image_attribute'] ?? 'src';
                  imageUrl = imageNode.attributes[attr] ?? '';
                }
                
                String id = titleNode?.attributes['href'] ?? '';

                if (title.isNotEmpty) {
                  extensionResults.add(Manga(
                    id: id,
                    title: title,
                    imageUrl: imageUrl.startsWith('//') ? 'https:$imageUrl' : imageUrl,
                    source: repo['name'] ?? repoUrl,
                  ));
                }
              }
           }
        }
      } else {
        HeadlessInAppWebView? headlessWebView;
        final completer = Completer<String?>();

        headlessWebView = HeadlessInAppWebView(
          initialData: InAppWebViewInitialData(
            data: """
              <!DOCTYPE html>
              <html>
              <head>
                <script>
                  ${response.body}
                </script>
              </head>
              <body></body>
              </html>
            """,
          ),
          initialSettings: InAppWebViewSettings(
            isFraudulentWebsiteWarningEnabled: false,
            allowsInlineMediaPlayback: true,
            allowUniversalAccessFromFileURLs: true,
            allowFileAccessFromFileURLs: true,
            userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
          ),
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(handlerName: 'nativeFetch', callback: (args) async {
              String targetUrl = args[0];
              try {
                final res = await http.get(Uri.parse(targetUrl), headers: {
                  'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
                });
                return res.body;
              } catch (e) {
                return "ERROR: $e";
              }
            });
          },
          onLoadStop: (controller, url) async {
            try {
              final injection = """
                window.fetch = async (url) => {
                  const body = await window.flutter_inappwebview.callHandler('nativeFetch', url);
                  if (body.startsWith("ERROR:")) throw new Error(body);
                  return {
                    text: async () => body,
                    json: async () => JSON.parse(body),
                    ok: true,
                    status: 200
                  };
                };
              """;
              await controller.evaluateJavascript(source: injection);

              final result = await controller.callAsyncJavaScript(
                functionBody: """
                  if (typeof searchManga === 'function') {
                    try {
                      let res = await searchManga(query);
                      return JSON.stringify(res);
                    } catch(err) {
                      return "ERROR: " + err.toString();
                    }
                  }
                  return null;
                """,
                arguments: {'query': query}
              );
              
              if (!completer.isCompleted) {
                if (result != null && result.error == null) {
                   completer.complete(result.value?.toString());
                } else {
                   completer.completeError(result?.error ?? 'Unknown JS Error');
                }
              }
            } catch (e) {
              if (!completer.isCompleted) completer.completeError(e);
            }
          },
          onLoadError: (controller, url, code, message) {
            print("Webview Load Error: $message");
            if (!completer.isCompleted) completer.completeError(message);
          },
          onConsoleMessage: (controller, consoleMessage) {
            print("JS Console [${repo['name']}]: ${consoleMessage.message}");
          }
        );

        await headlessWebView.run();
        final resultStr = await completer.future.timeout(const Duration(seconds: 15));

        print("Raw JS Result: $resultStr");

        if (resultStr != null && resultStr != 'null' && !resultStr.startsWith("ERROR:")) {
          final List<dynamic> jsonList = jsonDecode(resultStr);
          for (var item in jsonList) {
            extensionResults.add(Manga(
              id: item['id'].toString(),
              title: item['title'] ?? 'Unknown Title',
              imageUrl: item['imageUrl'] ?? ApiConstants.fallbackImageUrl,
              source: repo['name'] ?? repoUrl,
            ));
          }
        } else if (resultStr != null && resultStr.startsWith("ERROR:")) {
          print("Javascript Execution Error: $resultStr");
        }
        await headlessWebView.dispose();
      }
    } catch (e) {
      print("Extension Search Failed: $e");
    }
    return extensionResults;
  }

  Future<void> _performSearch({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => _isLoadingMore = true);
      _offset += _limit;
    } else {
      setState(() {
        _isLoading = true;
        _offset = 0;
        _results.clear();
        _hasMoreData = true;
      });
    }

    try {
      List<Manga> tempResults = [];

      final mdUrl = Uri.parse(ApiConstants.searchManga(widget.query, limit: _limit, offset: _offset));
      final mdResponse = await http.get(mdUrl);
      
      if (mdResponse.statusCode == 200) {
        final data = jsonDecode(mdResponse.body);
        for (var item in data['data']) {
          final id = item['id'];
          final titleMap = item['attributes']['title'] as Map<String, dynamic>;
          final title = titleMap['en'] ?? titleMap.values.first;

          String fileName = '';
          for (var rel in item['relationships']) {
            if (rel['type'] == 'cover_art') {
              fileName = rel['attributes']['fileName'] ?? '';
              break;
            }
          }

          tempResults.add(Manga(
            id: id,
            title: title.toString(),
            imageUrl: fileName.isNotEmpty
                ? ApiConstants.coverUrl(id, fileName)
                : ApiConstants.fallbackImageUrl,
            source: 'MangaDex',
          ));
        }
        if (data['data'].length < _limit) _hasMoreData = false;
      }

      if (!isLoadMore) {
        final String? reposJson = await StorageService.read('user_repos');
        if (reposJson != null) {
          final List<dynamic> repos = jsonDecode(reposJson);
          for (var repo in repos) {
             final extensionManga = await _searchExtension(repo, widget.query);
             tempResults.insertAll(0, extensionManga);
          }
        }
      }

      setState(() {
        if (isLoadMore) {
          _results.addAll(tempResults);
          _isLoadingMore = false;
        } else {
          _results = tempResults;
          _isLoading = false;
        }
      });
    } catch (e) {
      print("Universal Search Error: $e");
      setState(() {
         _isLoading = false;
         _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkForest),
        title: Text('Search: "${widget.query}"', style: const TextStyle(color: AppColors.darkForest, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.matchaGreen))
          : _results.isEmpty
          ? const Center(child: Text("No manga found. Try another title!", style: TextStyle(color: AppColors.mutedSage)))
          : ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        itemCount: _results.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _results.length) {
             return const Padding(
               padding: EdgeInsets.symmetric(vertical: 20),
               child: Center(child: CircularProgressIndicator(color: AppColors.matchaGreen)),
             );
          }
          final manga = _results[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MangaDetailsView(
                    mangaId: manga.id,
                    title: manga.title,
                    imageUrl: manga.imageUrl,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      manga.imageUrl,
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70, height: 100, color: const Color(0xFFE1EBE3),
                        child: const Icon(Icons.broken_image, color: AppColors.matchaGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          manga.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.darkForest),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.explore, size: 14, color: AppColors.mutedSage),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                manga.source == 'MangaDex' ? 'MangaDex' : 'Community Ext.',
                                style: const TextStyle(color: AppColors.mutedSage, fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

        },
      ),
    );
  }
}
