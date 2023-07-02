// ignore_for_file: file_names, use_build_context_synchronously

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DetailProdukPage extends StatelessWidget {
  final String productId;

  const DetailProdukPage({required this.productId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<void> deleteProduct() async {
      try {
        final productDocRef =
            FirebaseFirestore.instance.collection('products').doc(productId);
        final productData = (await productDocRef.get()).data();

        if (productData != null && productData['gambar_produk'] != null) {
          final storageRef = firebase_storage.FirebaseStorage.instance
              .refFromURL(productData['gambar_produk']);
          await storageRef.delete();
        }

        // Delete related order lists in pesanan_konsumen collection
        final orderListsQuery = await FirebaseFirestore.instance
            .collection('pesanan_konsumen')
            .where('id_produk', isEqualTo: productId)
            .get();

        for (final orderDoc in orderListsQuery.docs) {
          await orderDoc.reference.delete();
        }

        await productDocRef.delete();

        Fluttertoast.showToast(
          msg: 'Product deleted successfully!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pop(context);
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Failed to delete product! $e',
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
                  onPressed: deleteProduct,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Delete Product'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
