// lib/my_marks_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyMarksPage extends StatelessWidget {
  const MyMarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Marks'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        // 1. Get all assignments
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .orderBy('dueDate', descending: false)
            .snapshots(),
        builder: (context, assignmentSnapshot) {
          if (assignmentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!assignmentSnapshot.hasData || assignmentSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No assignments posted yet.',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          // 2. Display them in a list
          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: assignmentSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var assignmentDoc = assignmentSnapshot.data!.docs[index];
              Map<String, dynamic> assignmentData = assignmentDoc.data() as Map<String, dynamic>;
              String assignmentId = assignmentDoc.id;

              // 3. For each assignment, use a FutureBuilder to get the student's submission
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('assignments')
                    .doc(assignmentId)
                    .collection('submissions')
                    .doc(currentUser!.uid) // Get the doc matching the student's ID
                    .get(),
                builder: (context, submissionSnapshot) {
                  String grade = 'Not Graded';
                  String status = 'Not Submitted';
                  IconData icon = Icons.pending_actions;
                  Color iconColor = Colors.grey;

                  if (submissionSnapshot.connectionState == ConnectionState.done) {
                    if (submissionSnapshot.hasData && submissionSnapshot.data!.exists) {
                      // A submission exists
                      status = 'Submitted';
                      icon = Icons.check_circle;
                      iconColor = Colors.green;

                      // Check if it has a 'grade' field
                      Map<String, dynamic> subData = submissionSnapshot.data!.data() as Map<String, dynamic>;
                      if (subData.containsKey('grade') && subData['grade'] != null) {
                        grade = subData['grade'];
                        icon = Icons.school; // Graded icon
                        iconColor = Colors.blue;
                      } else {
                        grade = 'Submitted - Not Graded';
                      }
                    } else {
                      // No submission for this assignment
                      grade = 'Not Submitted';
                      icon = Icons.cancel;
                      iconColor = Colors.red;
                    }
                  }

                  // This is the card that displays the info
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: Icon(icon, color: iconColor, size: 40),
                      title: Text(
                        assignmentData['title'] ?? 'No Title',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        status,
                        style: TextStyle(color: iconColor, fontWeight: FontWeight.w500),
                      ),
                      trailing: Text(
                        grade,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}