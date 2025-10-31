// lib/main_navigation_shell.dart

import 'package:flutter/material.dart';
import 'feed_page.dart'; 
import 'profile_page.dart';
// import 'create_post_page.dart';
import 'ai_flashcard_page.dart';
import 'teacher_home_page.dart'; // We will use this soon
import 'create_assignment_page.dart'; // We already have this
import 'post_marks_page.dart'; 
import 'assignments_page.dart'; // <-- ADD THIS IMPORT// We will create this

class MainNavigationShell extends StatefulWidget {
  // We will pass the user's role to this page
  final String userRole;
  
  const MainNavigationShell({super.key, required this.userRole});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  // We need to store the pages and nav items
  late List<Widget> _pages;
  late List<Widget> _navButtons;
  late FloatingActionButton _floatingActionButton;

  @override
  void initState() {
    super.initState();
    // Build the correct UI based on the user's role
    if (widget.userRole == 'teacher') {
      _setupTeacherUI();
    } else {
      _setupStudentUI();
    }
  }

  // --- STUDENT UI ---
  // --- STUDENT UI (Updated for 4 tabs) ---
  void _setupStudentUI() {
    _pages = [
      const FeedPage(),
      const AssignmentsPage(), // <-- NEW
      const FlashcardPage(), 
      const ProfilePage(), 
    ];

    _navButtons = [
      _buildNavButton(icon: Icons.home, label: 'Home', index: 0),
      _buildNavButton(icon: Icons.assignment, label: 'Work', index: 1), // <-- NEW
      _buildNavButton(icon: Icons.psychology, label: 'AI Study', index: 2),
      _buildNavButton(icon: Icons.person, label: 'Profile', index: 3),
    ];

    // --- REMOVED THE FLOATING ACTION BUTTON ---
    _floatingActionButton = FloatingActionButton(
      onPressed: () {
        // This button is no longer visible on the student UI,
        // but we'll leave it here to avoid errors.
        // The "Create Post" button is now in the FeedPage AppBar.
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  // --- TEACHER UI ---
  void _setupTeacherUI() {
     _pages = [
      const TeacherHomePage(), // The dashboard we made
      const PostMarksPage(),   // A new placeholder page
      const ProfilePage(),     // Teachers need a profile page too
    ];

    _navButtons = [
      _buildNavButton(icon: Icons.dashboard, label: 'Dashboard', index: 0),
      _buildNavButton(icon: Icons.assignment_turned_in, label: 'Marks', index: 1),
      _buildNavButton(icon: Icons.person, label: 'Profile', index: 2),
    ];

     _floatingActionButton = FloatingActionButton(
      onPressed: () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAssignmentPage()));
      },
      backgroundColor: Colors.blue,
      child: const Icon(Icons.assignment_add, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      floatingActionButton: _floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        // This line adds the notch *only* for the teacher
        shape: widget.userRole == 'teacher' 
            ? const CircularNotchedRectangle() 
            : null,
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: widget.userRole == 'teacher'
              
              // --- TEACHER 3-BUTTON UI (with a gap for the FAB) ---
              ? [
                  _navButtons[0],
                  _navButtons[1],
                  const SizedBox(width: 40), // The gap
                  _navButtons[2],
                ]
              
              // --- STUDENT 4-BUTTON UI (no gap) ---
              : _navButtons, 
        ),
      ),
    );
  }

  // Helper widget to build a navigation button
  Widget _buildNavButton({required IconData icon, required String label, required int index}) {
    return MaterialButton(
      minWidth: 40,
      onPressed: () => setState(() { _selectedIndex = index; }),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index ? Colors.blue : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}