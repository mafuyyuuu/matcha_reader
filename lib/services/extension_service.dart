import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:html/parser.dart' as html_parser;
import '../models/manga.dart';
import '../models/chapter.dart';

class ExtensionService {
  /// Evaluates JS code in a headless webview to execute an extension function.
  Future<dynamic> _evaluateExtensionFunction(String repoUrl, String jsCall) async {
    final response = await http.get(Uri.parse(repoUrl));
    if (response.statusCode != 200) throw Exception("Failed to load extension code");

    HeadlessInAppWebView? headlessWebView;
    final completer = Completer<dynamic>();

    headlessWebView = HeadlessInAppWebView(
      initialData: InAppWebViewInitialData(data: """
        <!DOCTYPE html>
        <html>
        <head>
          <script>${response.body}</script>
        </head>
        <body></body>
        </html>
      """),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(handlerName: 'nativeFetch', callback: (args) async {
          try {
            final res = await http.get(Uri.parse(args[0]), headers: {
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
          await controller.evaluateJavascript(source: """
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
          """);
          
          final result = await controller.evaluateJavascript(source: jsCall);
          completer.complete(result);
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
    );

    await headlessWebView.run();
    try {
      final result = await completer.future.timeout(const Duration(seconds: 15));
      await headlessWebView.dispose();
      return result;
    } catch (e) {
      await headlessWebView.dispose();
      throw Exception("Extension execution failed: $e");
    }
  }

  /// VALIDATE & GET INFO
  Future<Map<String, dynamic>> getExtensionInfo(String repoUrl) async {
    final result = await _evaluateExtensionFunction(repoUrl, "typeof getExtensionInfo === 'function' ? JSON.stringify(getExtensionInfo()) : null");
    if (result != null && result.toString() != 'null') {
      return jsonDecode(result.toString());
    }
    throw Exception("getExtensionInfo not found or returned null.");
  }

  /// SEARCH
  Future<List<Manga>> searchManga(Map<String, dynamic> repo, String query) async {
    final repoUrl = repo['url'] as String;
    final repoType = repo['type'] as String? ?? 'js';

    List<Manga> extensionResults = [];

    if (repoType == 'json') {
      final response = await http.get(Uri.parse(repoUrl));
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
      // JavaScript Extension
      final jsCall = """
        (async () => {
          if (typeof searchManga === 'function') {
            try {
              let res = await searchManga('$query');
              return JSON.stringify(res);
            } catch(err) {
              return "ERROR: " + err.toString();
            }
          }
          return null;
        })()
      """;
      
      final result = await _evaluateExtensionFunction(repoUrl, jsCall);
      if (result != null && result.toString() != 'null' && !result.toString().startsWith("ERROR:")) {
        final List list = jsonDecode(result.toString());
        for (var item in list) {
          extensionResults.add(Manga(
            id: item['id'] ?? '',
            title: item['title'] ?? 'Unknown',
            imageUrl: item['imageUrl'] ?? '',
            source: repo['name'] ?? repoUrl,
          ));
        }
      }
    }
    return extensionResults;
  }

  /// DETAILS
  Future<Map<String, dynamic>> fetchMangaDetails(Map<String, dynamic> repo, String mangaId) async {
    final repoUrl = repo['url'] as String;
    final jsCall = """
      (async () => {
        if (typeof getMangaDetails === 'function') {
          try {
            let res = await getMangaDetails('$mangaId');
            return JSON.stringify(res);
          } catch(err) {
            return "ERROR: " + err.toString();
          }
        }
        return null;
      })()
    """;
    
    final result = await _evaluateExtensionFunction(repoUrl, jsCall);
    if (result != null && result.toString() != 'null' && !result.toString().startsWith("ERROR:")) {
      return jsonDecode(result.toString());
    }
    throw Exception("Failed to fetch extension details");
  }

  /// CHAPTERS
  Future<List<Chapter>> fetchMangaChapters(Map<String, dynamic> repo, String mangaId) async {
    final repoUrl = repo['url'] as String;
    final jsCall = """
      (async () => {
        if (typeof getMangaChapters === 'function') {
          try {
            let res = await getMangaChapters('$mangaId');
            return JSON.stringify(res);
          } catch(err) {
            return "ERROR: " + err.toString();
          }
        }
        return null;
      })()
    """;
    
    final result = await _evaluateExtensionFunction(repoUrl, jsCall);
    if (result != null && result.toString() != 'null' && !result.toString().startsWith("ERROR:")) {
      final List list = jsonDecode(result.toString());
      return list.map((c) => Chapter(
        id: c['id'] ?? '',
        number: c['number'] ?? '',
        date: c['date'] ?? 'Unknown Date',
      )).toList();
    }
    throw Exception("Failed to fetch extension chapters");
  }

  /// PAGES
  Future<List<String>> fetchChapterPages(Map<String, dynamic> repo, String chapterId) async {
    final repoUrl = repo['url'] as String;
    final jsCall = """
      (async () => {
        if (typeof getChapterPages === 'function') {
          try {
            let res = await getChapterPages('$chapterId');
            return JSON.stringify(res);
          } catch(err) {
            return "ERROR: " + err.toString();
          }
        }
        return null;
      })()
    """;
    
    final result = await _evaluateExtensionFunction(repoUrl, jsCall);
    if (result != null && result.toString() != 'null' && !result.toString().startsWith("ERROR:")) {
      final List list = jsonDecode(result.toString());
      return list.map((e) => e.toString()).toList();
    }
    throw Exception("Failed to fetch extension pages");
  }
}
