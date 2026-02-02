// lib/main_navigation_shell.dart

import 'package:flutter/material.dart';
import 'feed_page.dart'; 
import 'profile_page.dart';
import 'ai_flashcard_page.dart';
import 'teacher_home_page.dart'; 
import 'create_assignment_page.dart'; 
import 'assignments_page.dart';
import 'create_post_page.dart'; // <--- IMPORT THIS

class MainNavigationShell extends StatefulWidget {
  final String userRole;
  
  const MainNavigationShell({super.key, required this.userRole});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  late List<Widget> _pages;
  late List<Widget> _navButtons;
  FloatingActionButton? _floatingActionButton; 

  @override
  void initState() {
    super.initState();
    if (widget.userRole == 'teacher') {
      _setupTeacherUI();
    } else {
      _setupStudentUI();
    }
  }

  void _setupStudentUI() {
    _pages = [
      const FeedPage(),
      AssignmentsPage(userRole: widget.userRole), 
      const FlashcardPage(),
      ProfilePage(userRole: widget.userRole), 
    ];

    _navButtons = [
      _buildNavButton(icon: Icons.home, label: 'Feed', index: 0),
      _buildNavButton(icon: Icons.assignment, label: 'Tasks', index: 1),
      _buildNavButton(icon: Icons.flash_on, label: 'AI Study', index: 2),
      _buildNavButton(icon: Icons.person, label: 'Profile', index: 3),
    ];

    // --- NEW: Add the + Button for Students ---
    _floatingActionButton = FloatingActionButton(
      backgroundColor: Colors.black, // Instagram style black button
      child: const Icon(Icons.add_a_photo, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostPage()),
        );
      },
    );
  }

  void _setupTeacherUI() {
    _pages = [
      const TeacherHomePage(),
      AssignmentsPage(userRole: widget.userRole),
      const FeedPage(),
      ProfilePage(userRole: widget.userRole), 
    ];

    _navButtons = [
      _buildNavButton(icon: Icons.dashboard, label: 'Dashboard', index: 0),
      _buildNavButton(icon: Icons.assignment, label: 'Tasks', index: 1),
      _buildNavButton(icon: Icons.article, label: 'Feed', index: 2),
      _buildNavButton(icon: Icons.person, label: 'Profile', index: 3),
    ];

    // Teacher's "+" Button (Creates Assignment)
    _floatingActionButton = FloatingActionButton(
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateAssignmentPage()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Show FAB for BOTH Students and Teachers now
      floatingActionButton: _floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Cutout for the button
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: widget.userRole == 'teacher'
              ? [
                  _navButtons[0],
                  _navButtons[1],
                  const SizedBox(width: 40), // Gap
                  _navButtons[2],
                  _navButtons[3],
                ]
              : [
                  // Student Layout: 2 buttons, Gap, 2 buttons
                  _navButtons[0],
                  _navButtons[1],
                  const SizedBox(width: 40), // Gap for the Create Post button
                  _navButtons[2],
                  _navButtons[3],
                ], 
        ),
      ),
    );
  }

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
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}