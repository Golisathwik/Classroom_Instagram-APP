// lib/assignments_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'submit_assignment_page.dart';

class AssignmentsPage extends StatelessWidget {
  final String userRole;

  const AssignmentsPage({super.key, this.userRole = 'student'});

  // --- TEACHER ONLY: Delete Assignment ---
  Future<void> _deleteAssignment(BuildContext context, String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: const Text('Are you sure? This will delete all student submissions too.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('assignments').doc(docId).delete();
    }
  }

  // --- TEACHER ONLY: Edit Assignment ---
  void _editAssignment(BuildContext context, DocumentSnapshot doc) {
    TextEditingController titleController = TextEditingController(text: doc['title']);
    TextEditingController descController = TextEditingController(text: doc['description']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('assignments').doc(doc.id).update({
                'title': titleController.text,
                'description': descController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .orderBy('dueDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No assignments posted yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(10.0),
            children: snapshot.data!.docs.map((doc) {
              return _buildAssignmentCard(context, doc);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final String assignmentId = doc.id;
    final User? currentUser = FirebaseAuth.instance.currentUser;

    DateTime dueDate = (data['dueDate'] as Timestamp).toDate();
    String formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(dueDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ROW (Title + Teacher Icons) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (Expanded to prevent overflow)
                Expanded(
                  child: Text(
                    data['title'] ?? 'No Title',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                // --- TEACHER CONTROLS (Visible Buttons) ---
                if (userRole == 'teacher')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit',
                        onPressed: () => _editAssignment(context, doc),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _deleteAssignment(context, assignmentId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Due Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  'Due: $formattedDate',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              data['description'] ?? 'No Description',
              style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
            ),
            const SizedBox(height: 20),

            // --- STUDENT SUBMIT BUTTON ---
            if (userRole == 'student' && currentUser != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('assignments')
                    .doc(assignmentId)
                    .collection('submissions')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, submissionSnapshot) {
                  bool isSubmitted = 
                      submissionSnapshot.hasData && submissionSnapshot.data!.exists;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(isSubmitted ? Icons.check_circle : Icons.upload_file),
                      label: Text(isSubmitted ? 'Submitted' : 'Submit Assignment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubmitted ? Colors.green : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmitAssignmentPage(
                              assignmentId: assignmentId,
                              assignmentTitle: data['title'] ?? 'No Title',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}