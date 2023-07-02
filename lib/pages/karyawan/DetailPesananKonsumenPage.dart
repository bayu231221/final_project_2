// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DetailPesananKonsumenPage extends StatelessWidget {
  final String orderId;

  const DetailPesananKonsumenPage({Key? key, required this.orderId})
      : super(key: key);

  Future<void> _updateOrderStatus(
      String newStatus, BuildContext context) async {
    final orderRef =
        FirebaseFirestore.instance.collection('pesanan_konsumen').doc(orderId);

    try {
      await orderRef.update({'status': newStatus});

      // Show success toast message
      Fluttertoast.showToast(
        msg: 'Order status updated successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Send notification
      final orderData = await orderRef.get();
      final userId = orderData['user_id'] as String;

      FirebaseFirestore.instance
          .collection('notifikasi_konsumen')
          .doc(userId)
          .collection('notifications')
          .add({
        'message': 'Pesanan anda $newStatus',
        'timestamp': Timestamp.now(),
      });
    } catch (error) {
      // Show error toast message
      Fluttertoast.showToast(
        msg: 'Failed to update order status',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _showConfirmationDialog(
    String newStatus,
    BuildContext context,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Are you sure you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateOrderStatus(newStatus, context);
              },
              child: const Text('Confirm'),
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
        title: const Text('Detail Pesanan'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pesanan_konsumen')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final productId = orderData['id_produk'] as String;
          final namaProduk = orderData['nama_produk'] as String;
          final namaPembeli = orderData['nama_konsumen'] as String;
          final alamatPembeli = orderData['alamat_konsumen'] as String;
          final emailPembeli = orderData['email_konsumen'] as String;
          final nomorTeleponPembeli =
              orderData['nomor_ponsel_konsumen'] as String;
          final tanggalPemesanan = orderData['tanggal_pemesanan'] as String;
          final status = orderData['status'] as String;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('products')
                .doc(productId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final productData = snapshot.data!.data() as Map<String, dynamic>;
              final productImage = productData['gambar_produk'] as String;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Image.network(
                        productImage,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Order ID: $orderId',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nama Produk: $namaProduk',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nama Pembeli: $namaPembeli',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Alamat Pembeli: $alamatPembeli',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email Pembeli: $emailPembeli',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nomor Telepon Pembeli: $nomorTeleponPembeli',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tanggal Pemesanan: $tanggalPemesanan',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $status',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    if (status == 'menunggu konfirmasi')
                      ElevatedButton(
                        onPressed: () {
                          _showConfirmationDialog('sedang diantar', context);
                        },
                        child: const Text('Tandai sedang Diantar'),
                      ),
                    if (status == 'sedang diantar')
                      ElevatedButton(
                        onPressed: () {
                          _showConfirmationDialog('selesai diantar', context);
                        },
                        child: const Text('Tandai sudah selesai'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
