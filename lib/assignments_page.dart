// lib/assignments_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'submit_assignment_page.dart'; // <-- ADD THIS // We'll add this package for date formatting

class AssignmentsPage extends StatelessWidget {
  const AssignmentsPage({super.key});

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
        // Listen to the 'assignments' collection
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .orderBy('dueDate', descending: false) // Order by due date
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
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              
              // Format the due date
              DateTime dueDate = (data['dueDate'] as Timestamp).toDate();
              String formattedDate = DateFormat('EEE, MMM d, yyyy').format(dueDate); // e.g., "Fri, Oct 31, 2025"

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.blue, size: 40),
                  title: Text(
                    data['title'] ?? 'No Title',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['description'] ?? 'No Description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    'Due: $formattedDate',
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    // TODO: Show a detail page with the full description
                    _showAssignmentDetails(context, data, formattedDate, doc.id);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
  
  // --- Helper method to show assignment details in a pop-up ---
  void _showAssignmentDetails(BuildContext context, Map<String, dynamic> data, String formattedDate, String assignmentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                data['title'] ?? 'No Title',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Due Date
              Chip(
                label: Text('Due: $formattedDate', style: const TextStyle(color: Colors.red)),
                backgroundColor: Colors.red.shade50,
                avatar: const Icon(Icons.calendar_today, color: Colors.red, size: 16),
              ),
              const SizedBox(height: 8),

              // Posted by
              Text(
                'Posted by: ${data['postedBy'] ?? 'Unknown'}',
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 32),

              // Description
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    data['description'] ?? 'No Description',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_task),
                  label: const Text('Add or View Submission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Close the modal first
                    Navigator.pop(context); 
                    // Then navigate to the submission page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmitAssignmentPage(
                          assignmentId: assignmentId,
                          assignmentTitle: data['title'] ?? 'No Title', // Pass the title
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}