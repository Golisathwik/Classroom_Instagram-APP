// lib/ai_flashcard_page.dart

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// !! IMPORTANT !!
// Go to Google AI Studio to get your API key.
// DO NOT put your API key here in a real app. Use environment variables.
// But for a hackathon, this is the quickest way.
const String _apiKey = "AIzaSyAzmmNYm7TjcroFMkJPREN8Vx1ewDl_N4g";

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  final TextEditingController _notesController = TextEditingController();
  String _generatedFlashcards = '';
  bool _isLoading = false;

  Future<void> _generateFlashcards() async {
    if (_notesController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedFlashcards = '';
    });

    try {
      // Initialize the Model
      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // A faster, cost-efficient alternative
        apiKey: _apiKey,
      );

      // This is the "prompt" you send to the AI
      final prompt =
          'You are a helpful study assistant. Read the following notes and generate 5 question-and-answer flashcards. '
          'Format the output clearly with "Q:" for questions and "A:" for answers. \n\n'
          'Notes: "${_notesController.text}"';

      // Send the prompt to the AI
      final response = await model.generateContent([Content.text(prompt)]);

      // Display the AI's response
      setState(() {
        _generatedFlashcards = response.text ?? 'No response from AI.';
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _generatedFlashcards = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Flashcard Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Paste your lecture notes here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _generateFlashcards,
                      child: const Text('Generate Flashcards'),
                    ),
              const SizedBox(height: 24.0),
              // This is where the AI-generated text will appear
              if (_generatedFlashcards.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: SelectableText(_generatedFlashcards),
                ),
            ],
          ),
        ),
      ),
    );
  }
}