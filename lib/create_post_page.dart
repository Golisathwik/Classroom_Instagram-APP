// lib/create_post_page.dart

import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _postController = TextEditingController();
  bool _isLoading = false;

  // Variables to hold image data
  Uint8List? _imageBytes; // For web/mobile compatibility
  String? _imageName;

  // 1. Pick Image Function
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick the image
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Read the file as bytes (works on Web and Mobile)
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  // 2. Create Post Function
  Future<void> _createPost() async {
    // Validation: Check if both text and image are empty
    if (_postController.text.isEmpty && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add text or an image.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? downloadUrl;

      // --- STEP A: Upload Image to Storage (If one was selected) ---
      if (_imageBytes != null && _imageName != null) {
        // Create a unique file name using timestamp
        String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$_imageName';
        
        // Create the reference to Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child('post_images').child(fileName);

        // Upload the bytes with metadata (helps browser know it's an image)
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        UploadTask uploadTask = storageRef.putData(_imageBytes!, metadata);

        // Wait for upload to finish
        TaskSnapshot snapshot = await uploadTask;

        // !!! CRITICAL FIX !!! 
        // Get the public Link (https://...) not the file path
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // --- STEP B: Save Post to Firestore ---
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,              // ID of the user posting
        'caption': _postController.text, // The text content
        'imageUrl': downloadUrl,      // The public https link (can be null if text-only)
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],                  // Initialize empty likes list
        'commentCount': 0,            // Initialize comment count
      });

      // Close the page on success
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      // Handle Errors
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting: $e')),
        );
      }
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
              // --- Image Preview Area ---
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
                      // Show Icon if no image
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to add a photo', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      // Show Image if selected
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24.0),

              // --- Caption Text Field ---
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

              // --- Post Button ---
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
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