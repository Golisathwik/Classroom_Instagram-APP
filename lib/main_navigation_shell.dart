// lib/main_navigation_shell.dart

import 'package:flutter/material.dart';
import 'feed_page.dart'; 
import 'profile_page.dart';
import 'ai_flashcard_page.dart';
import 'teacher_home_page.dart'; 
import 'create_assignment_page.dart'; 
import 'assignments_page.dart';

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
  FloatingActionButton? _floatingActionButton; // Nullable for student

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
      // Pass role to AssignmentsPage
      AssignmentsPage(userRole: widget.userRole), 
      const FlashcardPage(),
      // Pass role to ProfilePage
      ProfilePage(userRole: widget.userRole), 
    ];

    _navButtons = [
      _buildNavButton(icon: Icons.home, label: 'Feed', index: 0),
      _buildNavButton(icon: Icons.assignment, label: 'Tasks', index: 1),
      _buildNavButton(icon: Icons.flash_on, label: 'AI Study', index: 2),
      _buildNavButton(icon: Icons.person, label: 'Profile', index: 3),
    ];
  }

  void _setupTeacherUI() {
    _pages = [
      const TeacherHomePage(),
      
      // --- FIX: ADDED THIS PAGE ---
      // Now the teacher can see the list of assignments and the Edit/Delete buttons
      AssignmentsPage(userRole: widget.userRole),
      
      const FeedPage(),
      ProfilePage(userRole: widget.userRole), 
    ];

    _navButtons = [
      _buildNavButton(icon: Icons.dashboard, label: 'Dashboard', index: 0),
      
      // --- FIX: ADDED THIS BUTTON ---
      _buildNavButton(icon: Icons.assignment, label: 'Tasks', index: 1),
      
      _buildNavButton(icon: Icons.article, label: 'Feed', index: 2),
      _buildNavButton(icon: Icons.person, label: 'Profile', index: 3),
    ];

    _floatingActionButton = FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateAssignmentPage()),
        );
      },
      child: const Icon(Icons.add),
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
        shape: widget.userRole == 'teacher' 
            ? const CircularNotchedRectangle() 
            : null,
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: widget.userRole == 'teacher'
              ? [
                  // Teacher Layout: 2 buttons, Gap, 2 buttons
                  _navButtons[0],
                  _navButtons[1],
                  const SizedBox(width: 40), // Gap for FAB
                  _navButtons[2],
                  _navButtons[3],
                ]
              : _navButtons, // Student Layout: Even spacing
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