// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously, file_names

import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoeswash/pages/pages.dart';

class BuatPesananPage extends StatefulWidget {
  static const routeName = '/buatpesananpage';
  const BuatPesananPage({Key? key}) : super(key: key);

  @override
  _BuatPesananPageState createState() => _BuatPesananPageState();
}

class _BuatPesananPageState extends State<BuatPesananPage> {
  File? _image;
  final picker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  Future pickImage() async {
    final pickedFile = await picker.getImage(
      source: ImageSource.gallery,
      maxWidth: 500, // Set the desired maximum width
      maxHeight: 500, // Set the desired maximum height
      imageQuality: 85, // Set the desired image quality (0-100)
    );

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<double> calculateAspectRatio() async {
    if (_image != null) {
      final image = Image.file(_image!);
      final Completer<Size> completer = Completer<Size>();

      image.image
          .resolve(const ImageConfiguration())
          .addListener(ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }));

      final Size imageSize = await completer.future;
      double aspectRatio = imageSize.width / imageSize.height;

      // Modify the aspect ratio based on your requirement
      if (aspectRatio > 4 / 3) {
        aspectRatio = 4 / 3;
      } else {
        aspectRatio = imageSize.width / imageSize.height;
      }

      return aspectRatio;
    }

    return 1 / 1; // Default aspect ratio if no image is selected
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  String? _validateRequiredField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    return null;
  }

  Future<void> _uploadImageToStorage() async {
    if (_image == null) {
      return;
    }

    final firebase_storage.Reference storageRef = firebase_storage
        .FirebaseStorage.instance
        .ref()
        .child('product_images/${DateTime.now().toIso8601String()}.jpg');
    await storageRef.putFile(_image!);
    final imageUrl = await storageRef.getDownloadURL();
    _sendDataToFirestore(imageUrl);
  }

  Future<void> _sendDataToFirestore(String imageUrl) async {
    if (_formKey.currentState!.validate()) {
      // All fields are valid, send data to Firestore
      final namaProduk = _productNameController.text;
      final hargaProduk = _priceController.text;
      final alamatProduk = _addressController.text;
      final deskripsiProduk = _deskripsiController.text;

      try {
        await FirebaseFirestore.instance.collection('products').add({
          'nama_produk': namaProduk,
          'gambar_produk': imageUrl,
          'harga_produk': hargaProduk,
          'alamat_produk': alamatProduk,
          'deskripsi_produk': deskripsiProduk,
        });

        // Clear the input fields
        _productNameController.clear();
        _priceController.clear();
        _addressController.clear();
        _deskripsiController.clear();
        setState(() {
          _image = null;
        });

        Fluttertoast.showToast(
          msg: 'Produk berhasil dibuat!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        Navigator.pushNamed(context, BerandaKaryawanPage.routeName);
      } catch (error) {
        Fluttertoast.showToast(
          msg: 'Terjadi kesalahan ketika mengirimkan data',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Produk'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (value) =>
                    _validateRequiredField(value, 'Nama Produk'),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => pickImage(),
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image != null
                      ? FutureBuilder<double>(
                          future: calculateAspectRatio(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final aspectRatio = snapshot.data!;
                              return AspectRatio(
                                aspectRatio: aspectRatio,
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              return Container();
                            }
                          },
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50),
                            SizedBox(height: 8),
                            Text('Tekan untuk menambah gambar'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga'),
                validator: (value) => _validateRequiredField(value, 'Harga'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                validator: (value) => _validateRequiredField(value, 'Alamat'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _deskripsiController,
                decoration:
                    const InputDecoration(labelText: 'Deskripsi Produk'),
                validator: (value) =>
                    _validateRequiredField(value, 'Deskripsi Produk'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _uploadImageToStorage(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 90,
                    vertical: 15,
                  ),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
