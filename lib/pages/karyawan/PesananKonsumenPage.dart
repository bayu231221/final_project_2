// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shoeswash/pages/pages.dart';

class PesananKonsumenPage extends StatelessWidget {
  static const routeName = '/pesanankonsumen';

  const PesananKonsumenPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Konsumen'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pesanan_konsumen')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;

              final orderId = orders[index].id;
              final namaKonsumen = order['nama_konsumen'] as String;
              final emailKonsumen = order['email_konsumen'] as String;
              final tanggalPemesanan = order['tanggal_pemesanan'] as String;
              final status = order['status'] as String;

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    alignment: Alignment.center,
                    width: 32,
                    height: 32,
                    child: Text(
                      (index + 1).toString(), // Incremental list on the left
                    ),
                  ),
                  title: Text(
                    'Order ID: $orderId',
                    style: const TextStyle(fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Nama Konsumen: $namaKonsumen',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Email Konsumen: $emailKonsumen',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tanggal Pemesanan: $tanggalPemesanan',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Status: $status',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPesananKonsumenPage(
                            orderId: orders[index].id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
