import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_colors.dart';
import '../core/constants/api_constants.dart';
import '../models/manga.dart';
import '../screens/home/home_view.dart';
import '../screens/discover/discover_view.dart';
import '../screens/library/library_view.dart';
import '../screens/sources/sources_view.dart';
import '../screens/settings/settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Manga> _trendingManga = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrendingManga();
  }

  Future<void> fetchTrendingManga() async {
    final url = Uri.parse(ApiConstants.trendingManga());

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Manga> tempManga = [];

        for (var item in data['data']) {
          final id = item['id'];
          final titleMap = item['attributes']['title'] as Map<String, dynamic>;
          final title = titleMap['en'] ?? titleMap.values.first;

          String fileName = '';
          for (var rel in item['relationships']) {
            if (rel['type'] == 'cover_art') {
              fileName = rel['attributes']['fileName'];
              break;
            }
          }

          tempManga.add(Manga(
            id: id,
            title: title,
            imageUrl: ApiConstants.coverUrl(id, fileName),
          ));
        }

        setState(() {
          _trendingManga = tempManga;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeView(mangaList: _trendingManga, isLoading: _isLoading),
      const DiscoverView(),
      const LibraryView(),
      const SourcesView(),
      const SettingsView(),
    ];

    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      resizeToAvoidBottomInset: false,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.matchaGreen,
        unselectedItemColor: AppColors.mutedSage,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'DISCOVER'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'LIBRARY'),
          BottomNavigationBarItem(icon: Icon(Icons.extension), label: 'SOURCES'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
    );
  }
}
