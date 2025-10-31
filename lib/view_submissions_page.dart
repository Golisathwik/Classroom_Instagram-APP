// lib/view_submissions_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewSubmissionsPage extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;

  const ViewSubmissionsPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<ViewSubmissionsPage> createState() => _ViewSubmissionsPageState();
}

class _ViewSubmissionsPageState extends State<ViewSubmissionsPage> {
  final _gradeController = TextEditingController();

  // --- Function to launch the file URL ---
  Future<void> _launchFileUrl(String url) async {
    final Uri fileUrl = Uri.parse(url);
    if (!await launchUrl(fileUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the file: $url')),
        );
      }
    }
  }

  // --- NEW: Function to show the grading pop-up dialog ---
  Future<void> _showGradeDialog(String submissionId, String currentGrade) async {
    _gradeController.text = currentGrade; // Pre-fill the text field with the current grade
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Post Mark'),
          content: TextField(
            controller: _gradeController,
            decoration: const InputDecoration(
              hintText: 'Enter grade (e.g., "A" or "95/100")',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Submit Mark'),
              onPressed: () {
                _submitGrade(submissionId, _gradeController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- NEW: Function to save the grade to Firestore ---
  Future<void> _submitGrade(String submissionId, String grade) async {
    if (grade.isEmpty) return; // Don't submit an empty grade

    try {
      // Get the reference to the student's submission document
      await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(submissionId) // This is the student's UID
          .update({
            'grade': grade,
            'gradedAt': FieldValue.serverTimestamp(),
          });
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mark posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post mark: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignmentTitle),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .doc(widget.assignmentId)
            .collection('submissions')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
            
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- THIS IS THE NEW FIX ---
          // Check for an error
          if (snapshot.hasError) {
            
            // 1. This prints the FULL link to your VS Code Debug Console
            print("!!! SUBMISSION INDEX ERROR: ${snapshot.error.toString()}");

            // 2. This is the new, shorter on-screen message
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Error: Missing Database Index.\n\nPlease check your VS Code "DEBUG CONSOLE" for a link to create the index. It starts with "https://console.firebase.google.com..."',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // --- END OF NEW FIX ---

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No submissions yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // We have submissions!
          return ListView(
            padding: const EdgeInsets.all(10.0),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              String submissionId = doc.id; // This is the student's UID
              
              DateTime submittedAt = (data['submittedAt'] as Timestamp).toDate();
              String formattedDate = DateFormat('MMM d, h:mm a').format(submittedAt);
              String currentGrade = data['grade'] ?? ''; // Get the current grade

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.green, size: 40),
                  title: Text(
                    data['studentEmail'] ?? 'Unknown Student',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Submitted: $formattedDate\nFile: ${data['fileName'] ?? 'No file'}'),
                  
                  // --- UPDATED TRAILING WIDGET ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View File Button
                      IconButton(
                        icon: const Icon(Icons.download_for_offline, color: Colors.blue),
                        tooltip: 'View File',
                        onPressed: () {
                          if (data['fileUrl'] != null) {
                            _launchFileUrl(data['fileUrl']);
                          }
                        },
                      ),
                      // Post Mark Button
                      IconButton(
                        icon: Icon(
                          Icons.school, 
                          color: currentGrade.isNotEmpty ? Colors.blue : Colors.grey
                        ),
                        tooltip: 'Post Mark',
                        onPressed: () {
                          // Pass the student's doc ID and current grade
                          _showGradeDialog(submissionId, currentGrade);
                        },
                      ),
                    ],
                  ),
                  // --- END OF UPDATE ---

                  onTap: () {
                    // Show the student's comment in a dialog
                    if (data['comment'] != null && data['comment'].isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Student Comment'),
                          content: Text(data['comment']),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}