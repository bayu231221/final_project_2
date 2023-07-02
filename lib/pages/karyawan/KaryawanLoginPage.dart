// ignore_for_file: use_build_context_synchronously, no_leading_underscores_for_local_identifiers, library_prefixes, file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shoeswash/pages/pages.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

class KaryawanLoginPage extends StatelessWidget {
  static const routeName = '/karyawanlogin';

  KaryawanLoginPage({Key? key}) : super(key: key);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> storeUserData(String userId, String role) async {
    final databasePath = await getDatabasesPath();
    final path = Path.join(databasePath, 'session_data.db');
    final database = await openDatabase(path, version: 1);

    await database.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR REPLACE INTO session(id, user_id, role) VALUES(?, ?, ?)',
        [1, userId, role],
      );
    });
  }

  Future<void> deleteUserData() async {
    final databasePath = await getDatabasesPath();
    final path = Path.join(databasePath, 'session_data.db');
    final database = await openDatabase(path, version: 1);

    await database.transaction((txn) async {
      await txn.rawDelete('DELETE FROM session WHERE id = ?', [1]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    void _loginButtonPressed() async {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(
          msg: 'Email and password are required',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      RegExp emailRegExp =
          RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
      if (!emailRegExp.hasMatch(email)) {
        Fluttertoast.showToast(
          msg: 'Invalid email format',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      try {
        final UserCredential userCredential =
            await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          final userId = userCredential.user!.uid;

          // Fetch user data from Firestore
          final userSnapshot = await FirebaseFirestore.instance
              .collection('karyawan')
              .doc(userId)
              .get();

          if (userSnapshot.exists) {
            final role = userSnapshot['role'];
            if (role == 'karyawan') {
              // User is a valid karyawan
              await storeUserData(userId, role); // Store user data in SQLite

              Fluttertoast.showToast(
                msg: 'Login berhasil!',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
              Navigator.pushReplacementNamed(
                context,
                BerandaKaryawanPage.routeName,
              );
            }
          } else {
            // User data not found in Firestore
            await deleteUserData();
            Fluttertoast.showToast(
              msg: 'Akun tidak ditemukan atau bukan karyawan!',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: 'Email atau password salah!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Terjadi kesalahan!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login sebagai Karyawan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginButtonPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 90,
                  vertical: 15,
                ),
              ),
              child: const Text('Login'),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, KaryawanRegisterPage.routeName);
              },
              child: const Text(
                'Belum punya akun? Daftar disini!',
                style: TextStyle(
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
