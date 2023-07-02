// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, library_prefixes, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

class PesananProdukKonsumenPage extends StatefulWidget {
  static const routeName = '/pesanan_produk_konsumen';

  const PesananProdukKonsumenPage({Key? key}) : super(key: key);

  @override
  _PesananProdukKonsumenPageState createState() =>
      _PesananProdukKonsumenPageState();
}

class _PesananProdukKonsumenPageState extends State<PesananProdukKonsumenPage> {
  String? userId; // User ID of the current logged-in user

  @override
  void initState() {
    super.initState();
    userId = null; // Initialize userId with null
    _getUserSession().then((userSession) {
      if (userSession == null) {
        // No user session found, handle accordingly
        return;
      }
      setState(() {
        userId = userSession['user_id']
            as String; // Assign the user_id to the variable
      });
    });
  }

  Future<Map<String, dynamic>?> _getUserSession() async {
    final databasePath = await getDatabasesPath();
    final path = Path.join(databasePath, 'session_data.db');
    Database database = await openDatabase(path);
    List<Map<String, dynamic>> sessionData =
        await database.rawQuery('SELECT * FROM session');
    return sessionData.isNotEmpty ? sessionData.first : null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchUserOrdersStream() {
    if (userId == null) {
      return Stream.error('User ID is null');
    }
    return FirebaseFirestore.instance
        .collection('pesanan_konsumen')
        .where('user_id', isEqualTo: userId)
        .snapshots();
  }

  Future<Map<String, dynamic>> _fetchProduct(String productId) async {
    final productDoc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    return productDoc.data() as Map<String, dynamic>;
  }

  void _showModal(BuildContext context, Map<String, dynamic> orderData) async {
    final productId = orderData['id_produk'];
    final productData = await _fetchProduct(productId);
    final productImage = productData['gambar_produk'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Order Details'),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (productImage != null)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: Image.network(
                        productImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  Text('Product ID: ${orderData['id_produk']}'),
                  const SizedBox(height: 8.0),
                  Text('Product Name: ${productData['nama_produk']}'),
                  const SizedBox(height: 8.0),
                  Text('Customer Address: ${orderData['alamat_konsumen']}'),
                  const SizedBox(height: 8.0),
                  Text('Order Date: ${orderData['tanggal_pemesanan']}'),
                  const SizedBox(height: 8.0),
                  Text('Status: ${orderData['status']}'),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Lists'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fetchUserOrdersStream(),
        builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to fetch orders'),
            );
          }
          final orders = snapshot.data?.docs ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('Pesanan anda lagi kosong'),
            );
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final orderData = orders[index].data();
              final orderNumber = index + 1;
              return GestureDetector(
                onTap: () {
                  _showModal(context, orderData);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    height: 100.0,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text('$orderNumber'),
                      ),
                      title: Text(
                        'Order ID: ${orders[index].id}',
                        style: const TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8.0),
                          Text(
                            'Product Name: ${orderData['nama_produk']}',
                            style: const TextStyle(fontSize: 14.0),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Order Date: ${orderData['tanggal_pemesanan']}',
                            style: const TextStyle(fontSize: 14.0),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Status: ${orderData['status']}',
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
