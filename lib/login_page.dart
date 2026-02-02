// lib/login_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_navigation_shell.dart';

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
  bool _isLoginView = true; // Toggle between Login and Sign Up
  
  // --- Role Selection Variables ---
  String _userRole = 'student'; // Default
  final List<bool> _isSelected = [true, false]; // [Student, Teacher]

  // --- 1. Forgot Password Function ---
  Future<void> _resetPassword() async {
    // Check if email is empty
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address above to reset your password.';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      
      setState(() {
        _errorMessage = ''; // Clear errors
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset link sent! Check your Email (and Spam).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'No user found with this email.';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Please enter a valid email address.';
        } else {
          _errorMessage = e.message ?? 'Error sending reset email.';
        }
      });
    }
  }

  // --- 2. Main Authentication Function ---
  Future<void> _authenticate() async {
    // Clear previous errors
    setState(() {
      _errorMessage = '';
    });

    // Check for empty fields
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginView) {
        // --- LOG IN ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        // After login, we need to fetch their role to navigate correctly
        String role = 'student'; // Default
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();
          if (userDoc.exists) {
            role = userDoc['role'] ?? 'student';
          }
        } catch (e) {
          debugPrint('Error fetching role: $e');
        }

        if (mounted) {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainNavigationShell(userRole: role)),
          );
        }

      } else {
        // --- SIGN UP ---
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Save user role to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'role': _userRole,
          'uid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainNavigationShell(userRole: _userRole)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // --- CUSTOM ERROR HANDLING ---
      String msg = 'An error occurred';
      
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        msg = 'Incorrect password. Please try again.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'This email is already registered. Try logging in.';
      } else if (e.code == 'invalid-email') {
        msg = 'The email address is invalid.';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak. Use at least 6 characters.';
      }

      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Icon
              const Icon(Icons.school, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Classroom App',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 40),

              // --- Role Toggle (Only show during Sign Up) ---
              if (!_isLoginView) ...[
                const Text('I am a:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                ToggleButtons(
                  isSelected: _isSelected,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _isSelected.length; i++) {
                        _isSelected[i] = i == index;
                      }
                      _userRole = index == 0 ? 'student' : 'teacher';
                    });
                  },
                  borderRadius: BorderRadius.circular(30),
                  selectedColor: Colors.white,
                  fillColor: Colors.blue,
                  color: Colors.blue,
                  constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
                  children: const [
                    Text('Student', style: TextStyle(fontSize: 16)),
                    Text('Teacher', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // --- Inputs ---
              _buildInputDecoration(hint: 'Email', icon: Icons.email, controller: _emailController),
              const SizedBox(height: 16.0),
              _buildInputDecoration(
                hint: 'Password', 
                icon: Icons.lock, 
                controller: _passwordController, 
                isPassword: true
              ),
              
              const SizedBox(height: 12.0),

              // --- Forgot Password Button (Only in Login Mode) ---
              if (_isLoginView)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Forgot Password?', style: TextStyle(color: Colors.grey)),
                  ),
                ),

              // --- Error Message Display ---
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24.0),

              // --- Action Button ---
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          _isLoginView ? 'Log In' : 'Sign Up',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
              const SizedBox(height: 24.0),

              // --- Toggle View Button ---
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginView = !_isLoginView;
                    _errorMessage = ''; // Clear errors when switching views
                    _emailController.clear();
                    _passwordController.clear();
                  });
                },
                child: Text(
                  _isLoginView 
                    ? "Don't have an account? Sign Up" 
                    : 'Already have an account? Log In',
                  style: const TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputDecoration({
    required String hint, 
    required IconData icon, 
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
      ),
    );
  }
}