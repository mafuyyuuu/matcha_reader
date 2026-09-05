import 'dart:io';
import 'dart:convert' as dart_convert;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../core/constants/api_constants.dart';

class DownloadService {
  Future<Set<String>> getDownloadedChapterIds(String mangaId, List<String> chapterIds) async {
    final dir = await getApplicationDocumentsDirectory();
    Set<String> downloaded = {};
    for (var chapId in chapterIds) {
      final chapDir = Directory('\${dir.path}/downloads/$mangaId/$chapId');
      if (await chapDir.exists() && chapDir.listSync().isNotEmpty) {
        downloaded.add(chapId);
      }
    }
    return downloaded;
  }

  Future<void> downloadChapter(String mangaId, String chapterId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('\${appDir.path}/downloads/$mangaId/$chapterId');
    
    if (await saveDir.exists() && saveDir.listSync().isNotEmpty) return;

    final url = Uri.parse(ApiConstants.atHomeServer(chapterId));
    final response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Failed to get chapter server');

    final data = dart_convert.jsonDecode(response.body); // Will use import 'dart:convert' as dart_convert;
    if (data['chapter'] != null) {
      final baseUrl = data['baseUrl'];
      final hash = data['chapter']['hash'];
      final List fileNames = data['chapter']['data'];
      
      if (!await saveDir.exists()) await saveDir.create(recursive: true);
      
      for (int i = 0; i < fileNames.length; i++) {
        final imgUrl = Uri.parse('\$baseUrl/data/\$hash/\${fileNames[i]}');
        final imgRes = await http.get(imgUrl);
        final file = File('\${saveDir.path}/page_$i.jpg');
        await file.writeAsBytes(imgRes.bodyBytes);
      }
    } else {
      throw Exception('Invalid chapter data');
    }
  }

  Future<List<String>> getChapterPages(String mangaId, String chapterId, {required Future<List<String>> Function() networkFallback}) async {
    final dir = await getApplicationDocumentsDirectory();
    final chapDir = Directory('\${dir.path}/downloads/$mangaId/$chapterId');
    
    // OFFLINE INTERCEPTOR: Check if chapter is downloaded locally
    if (await chapDir.exists()) {
      final files = chapDir.listSync().whereType<File>().toList();
      if (files.isNotEmpty) {
        // Sort files numerically (page_0, page_1, page_10)
        files.sort((a, b) {
          final aNum = int.tryParse(a.path.split('_').last.split('.').first) ?? 0;
          final bNum = int.tryParse(b.path.split('_').last.split('.').first) ?? 0;
          return aNum.compareTo(bNum);
        });
        return files.map((f) => f.path).toList();
      }
    }
    
    // Fallback to network
    return await networkFallback();
  }
}
