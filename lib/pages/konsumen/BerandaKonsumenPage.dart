// ignore_for_file: library_private_types_in_public_api, file_names, use_build_context_synchronously, library_prefixes

import 'package:flutter/material.dart';
import 'package:shoeswash/pages/pages.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

class BerandaKonsumenPage extends StatefulWidget {
  static const routeName = '/berandakonsumen';

  const BerandaKonsumenPage({Key? key}) : super(key: key);

  @override
  _BerandaKonsumenPageState createState() => _BerandaKonsumenPageState();
}

class _BerandaKonsumenPageState extends State<BerandaKonsumenPage> {
  int _currentPageIndex = 0; // Index of the current page

  final List<Widget> _pages = [
    const ShopPage(),
    const PesananProdukKonsumenPage(),
    const NotificationsPage(),
    const ProfilAkunKonsumenPage(),
  ];

  final List<IconData> _icons = [
    Icons.shopping_basket,
    Icons.list_alt,
    Icons.notifications,
    Icons.person,
  ];

  Future<bool> _checkSession() async {
    final databasePath = await getDatabasesPath();
    final path = Path.join(databasePath, 'session_data.db');
    Database database = await openDatabase(path);
    List<Map<String, dynamic>> sessionData =
        await database.rawQuery('SELECT * FROM session');
    return sessionData.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _checkSession().then((hasSession) {
      if (!hasSession) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          KonsumenLoginPage.routeName,
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: IndexedStack(
          index: _currentPageIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavbarIcon(0),
              _buildNavbarIcon(1),
              _buildNavbarIcon(2),
              _buildNavbarIcon(3),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavbarIcon(int pageIndex) {
    final icon = _icons[pageIndex];
    final color = _currentPageIndex == pageIndex ? Colors.blue : Colors.grey;

    return IconButton(
      onPressed: () {
        setState(() {
          _currentPageIndex = pageIndex;
        });
      },
      icon: Icon(
        icon,
        color: color,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konfirmasi'),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close the dialog

                    final databasePath = await getDatabasesPath();
                    final path = Path.join(databasePath, 'session_data.db');
                    Database database = await openDatabase(path);
                    await database.execute('DELETE FROM session');
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      MyHomePage.routeName,
                      (route) => false,
                    );
                  },
                  child: const Text('Keluar'),
                ),
              ],
            );
          },
        );
      },
      icon: const Icon(
        Icons.logout,
        color: Colors.grey,
      ),
    );
  }
}
