// ignore_for_file: library_prefixes

import 'package:flutter/material.dart';
import 'package:shoeswash/services/firebase_options.dart';
import 'pages/pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

void main() async {
  // Memastikan inisialisasi Flutter sudah terjadi
  WidgetsFlutterBinding.ensureInitialized();

  // Menginisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Menginisialisasi dan membuka database
  await _initializeDatabase();

  // Menjalankan aplikasi Flutter
  runApp(const MyApp());
}

Future<void> _initializeDatabase() async {
  // Mendapatkan path direktori database
  final databasePath = await getDatabasesPath();

  // Menggabungkan path direktori database dengan nama file database
  final path = Path.join(databasePath, 'session_data.db');

  // Membuka atau membuat database dengan versi 1
  await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
    // Membuat tabel 'session' jika belum ada
    await db.execute(
      'CREATE TABLE IF NOT EXISTS session (id INTEGER PRIMARY KEY, user_id TEXT, role TEXT)',
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'shoesWASH',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // Halaman awal aplikasi
      home: const MyHomePage(),
      routes: {
        // Penentuan rute halaman untuk navigasi
        MyHomePage.routeName: (context) => const MyHomePage(),
        KaryawanLoginPage.routeName: (context) => KaryawanLoginPage(),
        KonsumenLoginPage.routeName: (context) => KonsumenLoginPage(),
        BerandaKaryawanPage.routeName: (context) => const BerandaKaryawanPage(),
        BerandaKonsumenPage.routeName: (context) => const BerandaKonsumenPage(),
        BuatPesananPage.routeName: (context) => const BuatPesananPage(),
        DaftarPesananPage.routeName: (context) => const DaftarPesananPage(),
        ShopPage.routeName: (context) => const ShopPage(),
        PesananProdukKonsumenPage.routeName: (context) =>
            const PesananProdukKonsumenPage(),
        NotificationsPage.routeName: (context) => const NotificationsPage(),
        PesanNotifikasiPage.routeName: (context) => const PesanNotifikasiPage(),
        ProfilAkunKonsumenPage.routeName: (context) =>
            const ProfilAkunKonsumenPage(),
        KaryawanRegisterPage.routeName: (context) =>
            const KaryawanRegisterPage(),
        KonsumenRegisterPage.routeName: (context) =>
            const KonsumenRegisterPage(),
        PesananKonsumenPage.routeName: (context) => const PesananKonsumenPage(),
      },
    );
  }
}
