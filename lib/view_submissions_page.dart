// lib/view_submissions_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for input formatters
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
  final _marksController = TextEditingController();

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

  // --- NEW: Function to show the MARKS dialog (0-100) ---
  Future<void> _showMarkingDialog(String submissionId, String currentGrade) async {
    // If current grade is "Not Graded", clear the box. Otherwise show the number.
    _marksController.text = (currentGrade == 'Not Graded') ? '' : currentGrade;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Marks (0-100)'),
          content: TextField(
            controller: _marksController,
            keyboardType: TextInputType.number, // <--- Keypad for numbers
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // <--- Only allow digits
              LengthLimitingTextInputFormatter(3), // <--- Max 3 digits (e.g. 100)
            ],
            decoration: const InputDecoration(
              hintText: 'e.g., 85',
              border: OutlineInputBorder(),
              suffixText: '/ 100', // Shows "/ 100" inside the box
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String input = _marksController.text.trim();
                
                // VALIDATION LOGIC
                if (input.isEmpty) return;

                int? marks = int.tryParse(input);

                if (marks == null || marks < 0 || marks > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number between 0 and 100'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // If valid, save to Firestore
                await FirebaseFirestore.instance
                    .collection('assignments')
                    .doc(widget.assignmentId)
                    .collection('submissions')
                    .doc(submissionId)
                    .update({'grade': input}); // Saving as string is fine, or use marks (int)

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Marks'),
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
        title: Text('Submissions: ${widget.assignmentTitle}'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .doc(widget.assignmentId)
            .collection('submissions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No submissions yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12.0),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              
              // Get Data
              String submissionId = doc.id;
              String studentName = data['studentName'] ?? 'Unknown Student';
              String fileName = data['fileName'] ?? 'No File';
              String fileUrl = data['fileUrl'] ?? '';
              String currentGrade = data['grade'] ?? 'Not Graded';

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(studentName[0].toUpperCase()),
                  ),
                  title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              fileName, 
                              style: const TextStyle(color: Colors.blue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Marks: $currentGrade / 100', // UPDATED DISPLAY
                        style: TextStyle(
                          color: currentGrade == 'Not Graded' ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View File Button
                      if (fileUrl.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.grey),
                          tooltip: 'View File',
                          onPressed: () => _launchFileUrl(fileUrl),
                        ),
                      
                      // Grade Button
                      IconButton(
                        icon: Icon(
                          Icons.edit_note, // Changed icon to look like grading
                          color: currentGrade != 'Not Graded' ? Colors.blue : Colors.grey
                        ),
                        tooltip: 'Give Marks',
                        onPressed: () {
                          _showMarkingDialog(submissionId, currentGrade);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}