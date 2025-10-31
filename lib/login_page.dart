// lib/login_page.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = '';
  bool _isLoading = false;
  bool _isLoginView = true; // This will toggle between Login and Sign Up
  
  // --- NEW: For Role Selection ---
  String _userRole = 'student'; // Default role
  List<bool> _isSelected = [true, false]; // [Student, Teacher]
  // --- END NEW ---

  // --- Main Authentication Function ---
  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLoginView) {
        // --- Log In ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        // --- Sign Up ---
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        
        // --- NEW: Save user role to Firestore ---
        // Get the new user's ID
        String uid = userCredential.user!.uid;
        
        // Create a new document in the 'users' collection
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': _emailController.text,
          'role': _userRole, // This is 'student' or 'teacher'
          'uid': uid,
        });
        // --- END NEW ---
      }
      
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message ?? 'An unknown error occurred.'; });
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 100, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Classroom Instagram',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              Text(
                _isLoginView ? 'Welcome back!' : 'Create your account',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // --- NEW: Role Toggle (only show on Sign Up) ---
              if (!_isLoginView)
                ToggleButtons(
                  isSelected: _isSelected,
                  borderRadius: BorderRadius.circular(30.0),
                  fillColor: Colors.blue.withOpacity(0.1),
                  selectedColor: Colors.blue,
                  onPressed: (index) {
                    setState(() {
                      if (index == 0) {
                        _userRole = 'student';
                        _isSelected = [true, false];
                      } else {
                        _userRole = 'teacher';
                        _isSelected = [false, true];
                      }
                    });
                  },
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 24.0), child: Text('I am a Student')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 24.0), child: Text('I am a Teacher')),
                  ],
                ),
              if (!_isLoginView) const SizedBox(height: 24.0),
              // --- END NEW ---

              TextField(
                controller: _emailController,
                decoration: _buildInputDecoration(hint: 'Email', icon: Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),

              TextField(
                controller: _passwordController,
                decoration: _buildInputDecoration(hint: 'Password', icon: Icons.lock_outline),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),

              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
              if (_errorMessage.isNotEmpty) const SizedBox(height: 24.0),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: size.width * 0.7,
                      child: ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 5,
                        ),
                        child: Text(_isLoginView ? 'Log In' : 'Sign Up', style: const TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
              const SizedBox(height: 24.0),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginView = !_isLoginView;
                    _errorMessage = '';
                  });
                },
                child: Text(
                  _isLoginView ? "Don't have an account? Sign Up" : 'Already have an account? Log In',
                  style: const TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blue),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: const BorderSide(color: Colors.blue, width: 2.0)),
    );
  }
}