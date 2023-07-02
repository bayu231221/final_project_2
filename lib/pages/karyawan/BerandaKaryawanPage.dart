// ignore_for_file: no_leading_underscores_for_local_identifiers, use_build_context_synchronously, library_prefixes, file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shoeswash/pages/pages.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;
import 'package:fluttertoast/fluttertoast.dart';

/// Halaman Beranda Karyawan.
class BerandaKaryawanPage extends StatelessWidget {
  static const routeName = '/berandakaryawan';

  const BerandaKaryawanPage({Key? key}) : super(key: key);

  /// Mengambil nama akun berdasarkan ID pengguna.
  Future<String> getAccountName(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('karyawan')
        .doc(userId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return data['name'];
    } else {
      return '';
    }
  }

  /// Menghapus data sesi dari database lokal.
  Future<void> deleteSession() async {
    final databasePath = await getDatabasesPath();
    final path = Path.join(databasePath, 'session_data.db');
    final database = await openDatabase(path, version: 1);

    await database.transaction((txn) async {
      await txn.rawDelete('DELETE FROM session WHERE id = ?', [1]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;

    void _logoutButtonPressed() {
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

                  await deleteSession();
                  await auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, MyHomePage.routeName, (route) => false);
                },
                child: const Text('Keluar'),
              ),
            ],
          );
        },
      );
    }

    void _navigateToPesanNotifikasiPage() {
      Navigator.pushNamed(context, PesanNotifikasiPage.routeName);
    }

    void _navigateToPesananKonsumenPage() {
      Navigator.pushNamed(context, PesananKonsumenPage.routeName);
    }

    void _showChangePasswordDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          String newPassword = '';
          String confirmNewPassword = '';

          return AlertDialog(
            title: const Text('Ubah Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) {
                    newPassword = value;
                  },
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Baru',
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    confirmNewPassword = value;
                  },
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  if (newPassword.isNotEmpty &&
                      newPassword == confirmNewPassword) {
                    try {
                      final user = auth.currentUser;
                      if (user != null) {
                        await user.updatePassword(newPassword);
                        Fluttertoast.showToast(
                          msg: 'Password berhasil diubah.',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: 'Gagal mengubah password.',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                      if (kDebugMode) {
                        print('Error mengubah password: $e');
                      }
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg: 'Password tidak valid atau password tidak cocok.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  }
                },
                child: const Text('Ubah'),
              ),
            ],
          );
        },
      );
    }

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Beranda Karyawan'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getAccountInfoFromSession(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Terjadi kesalahan');
              } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                Future.microtask(() {
                  Navigator.pushNamedAndRemoveUntil(
                      context, KaryawanLoginPage.routeName, (route) => false);
                });
                return Container();
              } else {
                final accountName = snapshot.data!['name'] as String;
                final email = snapshot.data!['email'] as String;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Selamat datang, $accountName.',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Dengan email: $email',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, BuatPesananPage.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 94,
                          vertical: 15,
                        ),
                      ),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Buat Pesanan'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, DaftarPesananPage.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 90,
                          vertical: 15,
                        ),
                      ),
                      icon: const Icon(Icons.list),
                      label: const Text('Daftar Pesanan'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _navigateToPesananKonsumenPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 76,
                          vertical: 15,
                        ),
                      ),
                      icon: const Icon(Icons.people),
                      label: const Text('Pesanan Konsumen'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _navigateToPesanNotifikasiPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 86,
                          vertical: 15,
                        ),
                      ),
                      icon: const Icon(Icons.notifications),
                      label: const Text('Pesan Notifikasi'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showChangePasswordDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 87,
                          vertical: 15,
                        ),
                      ),
                      icon: const Icon(Icons.lock),
                      label: const Text('Ubah Password'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _logoutButtonPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 113,
                          vertical: 15,
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  /// Mengambil informasi akun dari session lokal.
  Future<Map<String, dynamic>> _getAccountInfoFromSession() async {
    final databasePath = await getDatabasesPath();
    final path = Path.join(databasePath, 'session_data.db');
    final database = await openDatabase(path, version: 1);

    final result =
        await database.query('session', where: 'id = ?', whereArgs: [1]);

    if (result.isNotEmpty) {
      final userId = result.first['user_id'] as String;

      final snapshot = await FirebaseFirestore.instance
          .collection('karyawan')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return {'name': data['name'], 'email': data['email']};
      } else {
        await deleteSession();
        await FirebaseAuth.instance.signOut();
        Navigator.pushNamedAndRemoveUntil(
            context as BuildContext, MyHomePage.routeName, (route) => false);
        return {};
      }
    } else {
      return {};
    }
  }
}
