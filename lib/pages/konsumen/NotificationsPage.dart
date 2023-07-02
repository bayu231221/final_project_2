// ignore_for_file: file_names, library_prefixes, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as Path;

class NotificationsPage extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Future<String?> _getUserSessionId() async {
    final databasePath = await getDatabasesPath();
    final path = Path.join(databasePath, 'session_data.db');
    Database database = await openDatabase(path);
    List<Map<String, dynamic>> sessionData =
        await database.rawQuery('SELECT * FROM session');
    if (sessionData.isNotEmpty) {
      final firstSession = sessionData.first;
      if (firstSession.containsKey('user_id')) {
        return firstSession['user_id'] as String?;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> _getUserNotifications() async {
    final userId = await _getUserSessionId();
    if (userId != null) {
      final konsumenNotifications = await FirebaseFirestore.instance
          .collection('notifikasi_konsumen')
          .doc(userId)
          .collection('notifications')
          .get();
      final karyawanNotifications = await FirebaseFirestore.instance
          .collection('notifikasi_karyawan')
          .get();
      final List<Map<String, dynamic>> allNotifications = [];

      if (konsumenNotifications.docs.isNotEmpty) {
        final konsumenData = konsumenNotifications.docs
            .map((snapshot) => {
                  'id': snapshot.id,
                  'message': snapshot.data()['message'],
                  'collection': 'notifikasi_konsumen',
                })
            .toList();
        allNotifications.addAll(konsumenData);
      }

      if (karyawanNotifications.docs.isNotEmpty) {
        final karyawanData = karyawanNotifications.docs
            .map((snapshot) => {
                  'id': snapshot.id,
                  'message': snapshot.data()['message'],
                  'collection': 'notifikasi_karyawan',
                })
            .toList();
        allNotifications.addAll(karyawanData);
      }

      return allNotifications;
    }
    return null;
  }

  Future<void> _deleteNotification(
    String notificationId,
    String collection,
  ) async {
    final userId = await _getUserSessionId();
    if (userId != null && collection == 'notifikasi_konsumen') {
      final notificationDoc = FirebaseFirestore.instance
          .collection('notifikasi_konsumen')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId);

      await notificationDoc.delete();

      setState(() {}); // Trigger rebuild after deletion
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _getUserNotifications(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<Map<String, dynamic>>?> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to fetch notifications'),
            );
          }

          final notifications = snapshot.data;

          if (notifications != null && notifications.isNotEmpty) {
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (BuildContext context, int index) {
                final notification = notifications[index];
                final notificationId = notification['id'] as String?;
                final message = notification['message'] as String?;
                final collection = notification['collection'] as String?;

                return ListTile(
                  title: Text(message ?? 'No notification available'),
                  trailing: collection == 'notifikasi_konsumen'
                      ? IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteNotification(
                              notificationId ?? '',
                              collection ?? '',
                            );
                          },
                        )
                      : null,
                );
              },
            );
          }

          return const Center(
            child: Text('No notifications available.'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () {
          setState(() {}); // Trigger rebuild to reload notifications
        },
      ),
    );
  }
}
