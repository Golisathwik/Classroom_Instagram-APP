// lib/submit_assignment_page.dart

import 'dart:io'; 
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

  File? _selectedFile;
  String? _fileName;

  // Function to pick a file
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  // Function to submit the assignment
  Future<void> _submitAssignment() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to submit.')),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() { _isLoading = true; });

    try {
      // 1. UPLOAD FILE
      String filePath = 'submissions/${widget.assignmentId}/${user.uid}/$_fileName';
      Reference storageRef = FirebaseStorage.instance.ref().child(filePath);
      
      UploadTask uploadTask = storageRef.putFile(_selectedFile!);
      TaskSnapshot snapshot = await uploadTask;
      String fileUrl = await snapshot.ref.getDownloadURL();

      // 2. SAVE TO FIRESTORE
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(user.uid)
          .set({
            'studentId': user.uid,
            'studentName': user.email, // <--- CHANGED: Using Email only
            'studentEmail': user.email,
            'fileUrl': fileUrl,
            'fileName': _fileName,
            'comment': _commentController.text.trim(),
            'submittedAt': FieldValue.serverTimestamp(),
            'grade': 'Not Graded',
          });

      if (mounted) {
        Navigator.pop(context); // Go back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
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
        title: const Text('Submit Work'),
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
                    border: Border.all(
                      color: _selectedFile != null ? Colors.green : Colors.grey.shade300, 
                      width: 2.0
                    ),
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
                              Text(
                                _fileName!, 
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
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