// lib/post_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'comments_page.dart'; // <-- ADD THIS IMPORT

class PostCard extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String postId; 

  const PostCard({
    super.key, 
    required this.postData,
    required this.postId,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late List<dynamic> likes;
  late bool isLiked;
  late int likeCount;
  String? currentUserId;
  
  // --- NEW: Add commentCount state ---
  late int commentCount;
  // --- END NEW ---

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Set the initial state from the post data
    likes = widget.postData['likes'] ?? [];
    likeCount = likes.length;
    isLiked = (currentUserId != null) ? likes.contains(currentUserId) : false;
    
    // --- NEW: Initialize commentCount ---
    commentCount = widget.postData['commentCount'] ?? 0;
    // --- END NEW ---
  }

  // --- LIKE/UNLIKE LOGIC (no change here) ---
  Future<void> _toggleLike() async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like posts.')),
      );
      return;
    }

    DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    
    setState(() {
      if (isLiked) {
        likeCount -= 1;
        isLiked = false;
        likes.remove(currentUserId);
      } else {
        likeCount += 1;
        isLiked = true;
        likes.add(currentUserId);
      }
    });

    try {
      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUserId])
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUserId])
        });
      }
    } catch (e) {
      // Revert UI on failure
      setState(() {
        if (isLiked) {
          likeCount -= 1;
          isLiked = false;
          likes.remove(currentUserId);
        } else {
          likeCount += 1;
          isLiked = true;
          likes.add(currentUserId);
        }
      });
    }
  }
  
  // --- NEW: Function to navigate to comments page ---
  void _goToComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsPage(postId: widget.postId),
      ),
    );
  }
  // --- END NEW ---

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = widget.postData['imageUrl'];
    final String text = widget.postData['text'] ?? '';
    final String userEmail = widget.postData['userEmail'] ?? 'Anonymous';
    final DateTime timestamp = (widget.postData['timestamp'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2.0,
      shape: const RoundedRectangleBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(userEmail[0].toUpperCase()),
            ),
            title: Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(timeago.format(timestamp)),
          ),

          if (imageUrl != null)
            Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                );
              },
            ),
          
          // --- POST ACTIONS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                // --- UPDATE COMMENT BUTTON ---
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  onPressed: _goToComments, // <-- Call new function
                ),
                // --- END UPDATE ---
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '$likeCount like${likeCount == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          const SizedBox(height: 8.0),

          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(text, style: const TextStyle(fontSize: 16.0)),
            ),
          
          // --- NEW: SHOW COMMENT COUNT ---
          if (commentCount > 0)
            GestureDetector(
              onTap: _goToComments,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'View all $commentCount comment${commentCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          // --- END NEW ---
          
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}