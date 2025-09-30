import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vault_trip/views/vault_browser/vault_browser_screen.dart';
import 'package:vault_trip/views/home/home_screen.dart';
import 'package:vault_trip/views/itinerary/itinerary_list_screen.dart';
import 'package:vault_trip/views/location/location_list_screen.dart';
import 'package:vault_trip/views/settings/settings_screen.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vault Trip',
      themeMode: ThemeMode.dark,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    ItineraryListScreen(),
    LocationListScreen(),
    VaultBrowserScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home),
            selectedIcon: Icon(Icons.home_outlined),
            label: '首頁',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            selectedIcon: Icon(Icons.calendar_today_outlined),
            label: '行程導覽',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            selectedIcon: Icon(Icons.map_outlined),
            label: '景點導覽',
          ),
          NavigationDestination(
            icon: Icon(Icons.notes),
            selectedIcon: Icon(Icons.notes_outlined),
            label: '筆記瀏覽',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings_outlined),
            label: '設定',
          ),
        ],
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
