// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shoeswash/pages/pages.dart';

class DaftarPesananPage extends StatelessWidget {
  static const routeName = '/daftarpesananpage';

  const DaftarPesananPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pesanan'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text('No products available'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (BuildContext context, int index) {
              final product = products[index].data() as Map<String, dynamic>?;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DetailProdukPage(productId: products[index].id),
                    ),
                  );
                },
                child: ListTile(
                  leading: Text('${index + 1}'),
                  title: Text(product?['nama_produk'] ?? ''),
                  subtitle: Text(product?['harga_produk'] ?? ''),
                  trailing: Text(product?['deskripsi_produk'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
