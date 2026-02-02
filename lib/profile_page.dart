// lib/profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_marks_page.dart';

class ProfilePage extends StatelessWidget {
  final String userRole;

  const ProfilePage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'), 
        backgroundColor: Colors.white, 
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView( 
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // --- SECTION 1: USER INFO ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50, 
                    backgroundColor: Colors.blue.shade100, 
                    child: Text(
                      user?.email?[0].toUpperCase() ?? 'U', 
                      style: const TextStyle(fontSize: 40, color: Colors.blue)
                    )
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.email ?? 'No Email', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 5),
                  Chip(
                    label: Text(
                      userRole.toUpperCase(), 
                      style: const TextStyle(color: Colors.white)
                    ), 
                    backgroundColor: Colors.blue
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- SECTION 2: BUTTONS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Only show "My Marks" if the user is a STUDENT
                  if (userRole == 'student') ...[
                    _buildProfileButton(
                      icon: Icons.grade,
                      text: 'My Marks',
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const MyMarksPage())
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Logout Button (For everyone)
                  _buildProfileButton(
                    icon: Icons.logout,
                    text: 'Log Out',
                    onTap: () {
                      FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
            ),
            
            // --- SECTION 3: MY POSTS (Only for Students) ---
            if (userRole == 'student') ...[
              const SizedBox(height: 30),
              const Divider(thickness: 2),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "My Posts", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('uid', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20), 
                      child: Text("You haven't posted anything yet.", style: TextStyle(color: Colors.grey))
                    );
                  }
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, 
                      crossAxisSpacing: 4, 
                      mainAxisSpacing: 4
                    ),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.error)),
                        ),
                      );
                    },
                  );
                },
              ),
            ], // End of Student Check
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- CUSTOM BUTTON HELPER ---
  Widget _buildProfileButton({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}