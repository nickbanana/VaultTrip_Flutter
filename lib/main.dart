import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vault_trip/providers/vault_provider.dart';
import 'package:vault_trip/views/document/document.dart';
import 'package:vault_trip/views/home/home.dart';
import 'package:vault_trip/views/point_of_interest/point_of_interest.dart';
import 'package:vault_trip/views/setting/setting.dart';
import 'package:vault_trip/views/travel_plan/travel_plan.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VaultProvider(),
      child: MaterialApp(
        title: 'Vault Trip',
        themeMode: ThemeMode.dark,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const MainPage(),
      ),
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
    HomeWidget(),
    TravelPlanWidget(),
    PointOfInterestWidget(),
    DocumentWidget(),
    SettingWidget(),
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
