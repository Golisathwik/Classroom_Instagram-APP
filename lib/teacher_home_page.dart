// lib/teacher_home_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'view_submissions_page.dart'; // We will create this file next

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        // We query the 'assignments' collection...
        stream: FirebaseFirestore.instance
            .collection('assignments')
            // ...and filter it to show ONLY assignments posted by THIS teacher
            .where('teacherId', isEqualTo: currentUser?.uid)
            .orderBy('postedAt', descending: true)
            .snapshots(),
            
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- THIS IS THE NEW, FIXED ERROR HANDLER ---
          if (snapshot.hasError) {
            
            // 1. This prints the FULL, complete link to your
            //    VS Code "DEBUG CONSOLE" (at the bottom).
            print("!!! REQUIRED FIREBASE INDEX: ${snapshot.error.toString()}");

            // 2. This is the new, shorter on-screen message
            //    that will NOT crash the app.
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
          // --- END OF NEW PART ---

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have not posted any assignments yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // We have assignments! Show them in a list.
          return ListView(
            padding: const EdgeInsets.all(10.0),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              DateTime dueDate = (data['dueDate'] as Timestamp).toDate();
              String formattedDate = DateFormat('MMM d, yyyy').format(dueDate);

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
                  subtitle: Text('Due: $formattedDate'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // When tapped, go to the View Submissions page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewSubmissionsPage(
                          assignmentId: doc.id,
                          assignmentTitle: data['title'] ?? 'No Title',
                        ),
                      ),
                    );
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