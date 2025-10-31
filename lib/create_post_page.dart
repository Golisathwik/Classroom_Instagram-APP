// lib/create_post_page.dart

import 'dart:typed_data'; // We need this to handle image bytes on web
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageSate();
}

class _CreatePostPageSate extends State<CreatePostPage> {
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;
  
  // --- THE FIX ---
  // We'll store the image as bytes (Uint8List) instead of a File.
  // This works on both web and mobile.
  Uint8List? _imageBytes;
  // --- END OF FIX ---

  String? _imageName; // To give the file a name in Storage

  // Function to let the user pick an image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // --- THE FIX ---
      // Read the file as bytes
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name; // Save the original file name
      });
      // --- END OF FIX ---
    }
  }

  // Function to create the post
  Future<void> _createPost() async {
    if (_postController.text.isEmpty && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add text or an image.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl;

      // 1. If an image is selected, upload it to Firebase Storage
      if (_imageBytes != null && _imageName != null) {
        String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$_imageName';
        Reference storageRef = FirebaseStorage.instance.ref().child('post_images').child(fileName);

        // --- THE FIX ---
        // Use putData() to upload bytes, instead of putFile()
        // We also add metadata to tell Storage it's an image.
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        UploadTask uploadTask = storageRef.putData(_imageBytes!, metadata);
        // --- END OF FIX ---

        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // 2. Add the post data to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'likes': [], // We should also initialize this!
        'commentCount': 0, // <-- ADD THIS LINE
      });

      if (mounted) { Navigator.pop(context); }

    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- 1. The Image Preview or "Pick Image" Box ---
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  ),
                  child: _imageBytes == null
                      // If no image is selected, show this
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to add a photo', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      // If an image IS selected, show it
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          // --- THE FIX ---
                          // Use Image.memory() to display bytes
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                          // --- END OF FIX ---
                        ),
                ),
              ),
              const SizedBox(height: 24.0),

              // --- 2. The Text Field ---
              TextField(
                controller: _postController,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24.0),

              // --- 3. The "Post" Button ---
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity, // Button is full width
                      child: ElevatedButton(
                        onPressed: _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Post',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}