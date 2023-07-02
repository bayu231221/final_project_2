// ignore_for_file: use_build_context_synchronously, library_prefixes, file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';

class KonsumenDetailProduk extends StatelessWidget {
  final String productId;

  const KonsumenDetailProduk({required this.productId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<void> addInvoiceData() async {
      try {
        final userSession = await _getUserSession();
        if (userSession == null) {
          Fluttertoast.showToast(
            msg: 'Failed to fetch user session!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
          return;
        }

        final productDocRef =
            FirebaseFirestore.instance.collection('products').doc(productId);

        final productSnapshot = await productDocRef.get();
        final productData = productSnapshot.data();

        if (!productSnapshot.exists || productData == null) {
          Fluttertoast.showToast(
            msg: 'Product not found!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
          return;
        }

        final userDocRef = FirebaseFirestore.instance
            .collection('konsumen')
            .doc(userSession['user_id']);

        final userSnapshot = await userDocRef.get();
        final userData = userSnapshot.data();
        if (!userSnapshot.exists || userData == null) {
          Fluttertoast.showToast(
            msg: 'User not found!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
          return;
        }

        final now = DateTime.now();
        final userTimezone = DateTime.now().timeZoneOffset;
        final formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(now);
        final formattedTimezone = userTimezone.isNegative
            ? '-${userTimezone.inHours.toString().padLeft(2, '0')}:${userTimezone.inMinutes.remainder(60).toString().padLeft(2, '0')}'
            : '+${userTimezone.inHours.toString().padLeft(2, '0')}:${userTimezone.inMinutes.remainder(60).toString().padLeft(2, '0')}';
        final orderDate = '$formattedDate$formattedTimezone';

        final isoDate = now.toIso8601String(); // Add isoDate

        final invoiceData = {
          'id_produk': productSnapshot.id,
          'nama_produk': productData['nama_produk'],
          'harga_produk': productData['harga_produk'],
          'email_konsumen': userData['email'],
          'nama_konsumen': userData['name'],
          'alamat_konsumen': userData['address'],
          'nomor_ponsel_konsumen': userData['phone_number'],
          'user_id': userSession['user_id'],
          'status': 'menunggu konfirmasi',
          'tanggal_pemesanan': orderDate,
          'isoDate': isoDate, // Add isoDate in invoiceData
        };

        final newNotification = {
          'message': 'Order berhasil, menunggu konfirmasi untuk dikirim',
          'timestamp': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('pesanan_konsumen')
            .add(invoiceData);

        final user = await _getCurrentUser();
        if (user != null) {
          final userNotificationDocRef = FirebaseFirestore.instance
              .collection('notifikasi_konsumen')
              .doc(user.id)
              .collection('notifications')
              .doc();
          await userNotificationDocRef.set(newNotification);
        }

        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: 'Anda berhasil memesan!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Gagal memesan!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Terjadi kesalahan!');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final productData = snapshot.data!.data() as Map<String, dynamic>?;

          if (productData == null) {
            return const Center(child: Text('Produk tidak ditemukan'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      productData['gambar_produk'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nama Produk: ${productData['nama_produk'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Harga Produk: ${productData['harga_produk'] ?? ''}'),
                const SizedBox(height: 8),
                Text(
                  'Deskripsi Produk: ${productData['deskripsi_produk'] ?? ''}',
                ),
                const SizedBox(height: 8),
                Text('Alamat Produk: ${productData['alamat_produk'] ?? ''}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: addInvoiceData,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Order Product'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserSession() async {
    final databasePath = await getDatabasesPath();
    final path = Path.join(databasePath, 'session_data.db');
    Database database = await openDatabase(path);
    List<Map<String, dynamic>> sessionData =
        await database.rawQuery('SELECT * FROM session');
    await database.close();
    return sessionData.isNotEmpty ? sessionData.first : null;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getCurrentUser() async {
    final userSession = await _getUserSession();
    if (userSession == null) return null;
    final userId = userSession['user_id'] as String?;
    if (userId != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('konsumen').doc(userId);
      final userSnapshot = await userDoc.get();
      if (userSnapshot.exists) {
        return userSnapshot;
      }
    }
    return null;
  }
}
