// lib/submit_assignment_page.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubmitAssignmentPage extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;

  const SubmitAssignmentPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<SubmitAssignmentPage> createState() => _SubmitAssignmentPageState();
}

class _SubmitAssignmentPageState extends State<SubmitAssignmentPage> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  // FilePicker data
  Uint8List? _fileBytes;
  String? _fileName;

  // Function to pick a file
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
        withData: true, // This is crucial for web
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _fileBytes = result.files.first.bytes;
          _fileName = result.files.first.name;
        });
      } else {
        // User canceled the picker
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  // Function to submit the assignment
  Future<void> _submitAssignment() async {
    if (_fileBytes == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to submit.')),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() { _isLoading = true; });

    try {
      // 1. Upload the file to Firebase Storage
      String filePath = 'submissions/${widget.assignmentId}/${user.uid}/$_fileName';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
      
      final metadata = SettableMetadata(contentType: 'application/octet-stream');
      UploadTask uploadTask = storageRef.putData(_fileBytes!, metadata);
      
      TaskSnapshot snapshot = await uploadTask;
      String fileUrl = await snapshot.ref.getDownloadURL();

      // 2. Create the submission document in Firestore
      // We'll store this in a subcollection under the assignment
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(user.uid) // Use the user's ID as the doc ID
          .set({
            'studentId': user.uid,
            'studentEmail': user.email,
            'fileUrl': fileUrl,
            'fileName': _fileName,
            'comment': _commentController.text,
            'submittedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context); // Go back to the assignment list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
      }

    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Work'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.assignmentTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32.0),

              // --- File Picker Button ---
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: _fileName == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to select a file (PDF, DOC, PNG...)', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, size: 50, color: Colors.green),
                              const SizedBox(height: 8),
                              Text(_fileName!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // --- Comment Field ---
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a private comment to your teacher...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24.0),

              // --- Submit Button ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Mark as Done'),
                        onPressed: _submitAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
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