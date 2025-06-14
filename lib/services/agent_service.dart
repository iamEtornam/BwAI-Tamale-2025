import 'dart:async';
import 'dart:developer';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

enum AgentRole { storyAssistant, imageCreator, editor }

class AgentMessage {
  final String text;
  final bool isFromAgent;
  final DateTime timestamp;

  AgentMessage({
    required this.text,
    required this.isFromAgent,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AgentService with ChangeNotifier {
  // Stream controller for agent messages
  final _messagesController = StreamController<AgentMessage>.broadcast();
  Stream<AgentMessage> get messageStream => _messagesController.stream;

  // Current agent role
  AgentRole _currentRole = AgentRole.storyAssistant;
  AgentRole get currentRole => _currentRole;

  // Chat history
  final List<AgentMessage> _history = [];
  List<AgentMessage> get history => List.unmodifiable(_history);

  // Conversation context
  final Map<String, dynamic> _context = {};

  // Firebase AI model
  late final model = FirebaseAI.vertexAI().imagenModel(
    model: 'imagen-3.0-generate-002',
  );

  // Add a message to the conversation
  void addMessage(String text, {bool isFromAgent = false}) {
    final message = AgentMessage(text: text, isFromAgent: isFromAgent);
    _history.add(message);
    _messagesController.add(message);
    notifyListeners();
  }

  // Change the agent's role
  void changeRole(AgentRole role) {
    _currentRole = role;

    // Send a message indicating the role change
    String roleMessage = '';
    switch (role) {
      case AgentRole.storyAssistant:
        roleMessage =
            "I'm now your Story Assistant. I'll help you craft engaging stories.";
        break;
      case AgentRole.imageCreator:
        roleMessage =
            "I'm now your Image Creator. I'll help you generate visuals for your story.";
        break;
      case AgentRole.editor:
        roleMessage =
            "I'm now your Editor. I'll help you refine and improve your story.";
        break;
    }

    addMessage(roleMessage, isFromAgent: true);
  }

  // Update context with new information
  void updateContext(Map<String, dynamic> newContext) {
    _context.addAll(newContext);
  }

  // Get a suggestion based on current context
  Future<String> getSuggestion({String? input}) async {
    String suggestion = '';

    switch (_currentRole) {
      case AgentRole.storyAssistant:
        suggestion = _getStoryAssistantSuggestion();
        break;
      case AgentRole.imageCreator:
        suggestion = _getImageCreatorSuggestion();
        break;
      case AgentRole.editor:
        suggestion = _getEditorSuggestion();
        break;
    }

    addMessage(suggestion, isFromAgent: true);
    return suggestion;
  }

  // Generate a suggestion for story writing
  String _getStoryAssistantSuggestion() {
    final suggestions = [
      "How about adding a twist to your story? Something unexpected could happen to your main character.",
      "Consider developing your setting more. What makes this world unique?",
      "Your protagonist needs a clear motivation. What drives them forward?",
      "Every good story has conflict. What obstacles can you put in your character's way?",
      "Think about the emotional journey of your character. How do they change by the end?",
      "Adding sensory details can bring your story to life. What does your world smell, sound, and feel like?",
    ];

    return suggestions[DateTime.now().millisecond % suggestions.length];
  }

  // Generate a suggestion for image creation
  String _getImageCreatorSuggestion() {
    final suggestions = [
      "Try selecting contrasting scenes to make your story more dynamic.",
      "Images with characters tend to make stories more relatable.",
      "Landscapes can set the mood for your entire story.",
      "Consider images with interesting lighting to create atmosphere.",
      "Fantasy elements in images can spark creative storylines.",
    ];

    return suggestions[DateTime.now().millisecond % suggestions.length];
  }

  // Generate a suggestion for editing
  String _getEditorSuggestion() {
    final suggestions = [
      "Check your story for pacing. Does it flow naturally from scene to scene?",
      "Make sure your dialogue sounds natural by reading it aloud.",
      "Look for repeated words or phrases that could be replaced with more varied language.",
      "Ensure your story has a satisfying conclusion that resolves the main conflict.",
      "Consider adding more descriptive details to bring key scenes to life.",
    ];

    return suggestions[DateTime.now().millisecond % suggestions.length];
  }

  // Analyze story and provide feedback
  Future<String> analyzeStory(String story) async {
    // In a real implementation, you would call an LLM here to analyze the story
    // For now, we'll provide some generic feedback based on length

    if (story.length < 500) {
      return "Your story is quite short. Consider expanding on the setting, characters, or plot to create a more immersive experience.";
    } else if (story.length < 1000) {
      return "Your story has a good length. To improve it further, you might want to add more dialogue or sensory details.";
    } else {
      return "You've written a substantial story! Make sure to check for pacing and ensure all plot threads are resolved.";
    }
  }

  // Suggest improvements to image prompts
  Future<List<String>> improveImagePrompts(List<String> prompts) async {
    // In a real implementation, you would call an LLM to improve the prompts
    // For now, we'll just enhance them with some additional details

    final improvedPrompts =
        prompts.map((prompt) {
          if (prompt.length < 50) {
            return "$prompt with dramatic lighting and detailed textures";
          } else {
            return prompt;
          }
        }).toList();

    return improvedPrompts;
  }

  // Generate a story based on text prompts and images
  Future<String> generateStory(
    String textPrompt,
    List<ImagenInlineImage> images,
  ) async {
    try {
      // Get Gemini model from Firebase AI
      final geminiModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
      );

      // Create content with text and images
      final content = TextPart(textPrompt);
      final imageParts =
          images
              .map(
                (image) =>
                    InlineDataPart('image/png', image.bytesBase64Encoded),
              )
              .toList();

      // Generate content with multimodal input
      final response = await geminiModel.generateContent([
        Content.multi([content, ...imageParts]),
      ]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Failed to generate story content');
      }

      return response.text!;
    } catch (e) {
      log('Error generating story: $e');
      throw Exception('Error generating story: $e');
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _messagesController.close();
    super.dispose();
  }
}
