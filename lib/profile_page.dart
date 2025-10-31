// lib/profile_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'my_marks_page.dart'; // <-- ADD THIS

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.grey[100], // Light grey background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // --- Profile Avatar ---
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  user?.email?[0].toUpperCase() ?? 'U', // First letter of email
                  style: const TextStyle(fontSize: 60, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- User Email ---
              Text(
                user?.email ?? 'Loading...',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // --- Menu Buttons ---
              // --- Menu Buttons ---
              _buildProfileButton(
                icon: Icons.assignment,
                text: 'My Marks',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyMarksPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildProfileButton(
                icon: Icons.calendar_today,
                text: 'My Attendance',
                onTap: () {
                  // TODO: Navigate to attendance page
                },
              ),
              const SizedBox(height: 16),
              _buildProfileButton(
                icon: Icons.settings,
                text: 'Settings',
                onTap: () {
                  // TODO: Navigate to settings page
                },
              ),
              const Spacer(), // Pushes logout button to the bottom

              // --- Logout Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for profile menu buttons
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