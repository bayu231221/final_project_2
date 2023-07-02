// ignore_for_file: library_private_types_in_public_api, file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PesanNotifikasiPage extends StatefulWidget {
  static const routeName = '/pesannotifikasipage';

  const PesanNotifikasiPage({Key? key}) : super(key: key);

  @override
  _PesanNotifikasiPageState createState() => _PesanNotifikasiPageState();
}

class _PesanNotifikasiPageState extends State<PesanNotifikasiPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final List<String> _notifications = [];

  Future<void> _addNotification() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      try {
        final documentRef =
            await _firestore.collection('notifikasi_karyawan').add({
          'message': message,
        });
        final notificationId = documentRef.id;
        setState(() {
          _notifications.add(notificationId);
        });
        _messageController.clear();
        Fluttertoast.showToast(msg: 'Notification added');
      } catch (error) {
        Fluttertoast.showToast(msg: 'Failed to add notification');
      }
    } else {
      Fluttertoast.showToast(msg: 'Please enter a notification message');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifikasi_karyawan')
          .doc(notificationId)
          .delete();
      setState(() {
        _notifications.remove(notificationId);
      });
      Fluttertoast.showToast(msg: 'Notification deleted');
    } catch (error) {
      Fluttertoast.showToast(msg: 'Failed to delete notification');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Notifikasi'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add Notification'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null, // Allow multiple lines
                      decoration: const InputDecoration(
                          labelText: 'Notification Message'),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addNotification();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('notifikasi_karyawan').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!.docs;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final notificationId = notification.id;
              final message = notification['message'];
              return ListTile(
                leading: Text((index + 1).toString()),
                title: Text(message),
                trailing: IconButton(
                  onPressed: () => _deleteNotification(notificationId),
                  icon: const Icon(Icons.delete),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
