// lib/create_post_page.dart

import 'dart:io'; // Required for File
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

  // Variables to hold image data (Fixed for Mobile Stability)
  File? _imageFile; 

  // 1. Pick Image Function
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick the image
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        // Use File object instead of bytes to prevent Out-Of-Memory crashes
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 2. Create Post Function
  Future<void> _createPost() async {
    // Validation: Check if both text and image are empty
    if (_postController.text.isEmpty && _imageFile == null) {
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
      if (_imageFile != null) {
        // Create a unique file name using timestamp
        String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Create the reference to Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child('post_images').child(fileName);

        // Upload using putFile (Stream upload - Safe for large files)
        UploadTask uploadTask = storageRef.putFile(_imageFile!);

        // Wait for upload to finish
        TaskSnapshot snapshot = await uploadTask;

        // Get the public Link
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // --- STEP B: Save Post to Firestore ---
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,              // ID of the user posting
        'email': user.email,          // Store email for display
        'caption': _postController.text.trim(), 
        'imageUrl': downloadUrl,      // The public https link
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],                  // Initialize empty likes list
        'commentCount': 0,            // Initialize comment count
      });

      // Close the page on success
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posted successfully!')),
        );
      }

    } catch (e) {
      // Handle Errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: Colors.white,
        elevation: 1.0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
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
                  child: _imageFile == null
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
                          child: Image.file(
                            _imageFile!, // Use Image.file for local files
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