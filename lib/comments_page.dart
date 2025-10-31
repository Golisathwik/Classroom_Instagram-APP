// lib/comments_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsPage extends StatefulWidget {
  // We must pass in the post ID to know which comments to show
  final String postId; 
  const CommentsPage({super.key, required this.postId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isPosting = false;

  // --- Post Comment Function ---
  Future<void> _postComment() async {
    if (_commentController.text.isEmpty || _currentUser == null) {
      return; // Do nothing if text is empty or user is not logged in
    }

    // NEW: Create a local, non-nullable variable.
    // Dart now knows 'user' can't be null.
    final User user = _currentUser;

    setState(() { _isPosting = true; });

    try {
      // We will use a "batch write" to do two things at once:
      // 1. Add the new comment to the 'comments' subcollection.
      // 2. Increment the 'commentCount' on the main 'post' document.
      
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Reference to the new comment document
      DocumentReference newCommentRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(); // Creates a new doc with a random ID

      batch.set(newCommentRef, {
        'text': _commentController.text,
        'userEmail': user.email, // No '!' needed
        'userId': user.uid,     // No '!' needed
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Reference to the main post document
      DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      
      batch.update(postRef, {
        // This atomically increments the counter
        'commentCount': FieldValue.increment(1),
      });

      // Commit both writes at the same time
      await batch.commit();

      // Clear the text field
      _commentController.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    } finally {
      setState(() { _isPosting = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Colors.white,
        elevation: 1.0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- 1. List of Comments ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Listen to the 'comments' subcollection of our post
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true) // Newest comments first
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }

                // We have comments! Show them in a ListView
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    
                    DateTime timestamp;
                    if (data['timestamp'] == null) {
                      timestamp = DateTime.now(); // Fallback
                    } else {
                      timestamp = (data['timestamp'] as Timestamp).toDate();
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Text(data['userEmail'][0].toUpperCase()),
                      ),
                      title: Text(
                        data['userEmail'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        data['text'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: Text(
                        timeago.format(timestamp, locale: 'en_short'),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          
          const Divider(height: 1.0),

          // --- 2. Comment Input Field ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                _isPosting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _postComment,
                    )
              ],
            ),
          )
        ],
      ),
    );
  }
}