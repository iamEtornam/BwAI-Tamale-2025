import 'dart:developer' as logger;
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:story_teller/services/agent_service.dart';
import 'package:story_teller/widgets/agent_assistant.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  // Model for image generation
  final model = FirebaseAI.vertexAI().imagenModel(
    model: 'imagen-3.0-generate-002',
  );

  // List of generated images
  List<ImagenInlineImage> _generatedImages = [];

  // List of generated prompts
  List<String> _generatedPrompts = [];

  // Selected images (max 3)
  final Set<int> _selectedImageIndices = {};

  // Loading states
  bool _isGeneratingImages = false;
  bool _isGeneratingStory = false;

  // Generated story
  String? _generatedStory;

  // Error messages
  String? _errorMessage;
  // Generate 4 images using Gemini-generated prompts
  Future<void> _generateImages() async {
    // Get the agent service
    final agentService = Provider.of<AgentService>(context, listen: false);

    // Set the agent to image creator mode and notify the user
    agentService.changeRole(AgentRole.imageCreator);
    agentService.addMessage(
      "I'll help you generate some creative images for your story.",
      isFromAgent: true,
    );

    setState(() {
      _isGeneratingImages = true;
      _errorMessage = null;
      _selectedImageIndices.clear();
      _generatedStory = null;
    });

    try {
      _generatedImages = [];
      _generatedPrompts = [];

      // First, use Gemini to generate creative image prompts
      // Since we can't directly use Gemini with this package, we'll simulate it
      // by creating more dynamic prompts based on themes
      final creativePrompts = await _generateCreativePrompts();
      _generatedPrompts = creativePrompts;

      // Update the agent with the prompts being used
      agentService.addMessage(
        "Generating images with these creative prompts:\n• ${creativePrompts.join('\n• ')}",
        isFromAgent: true,
      );

      // Generate images for each prompt
      for (final prompt in creativePrompts) {
        final response = await model.generateImages(prompt);
        if (response.images.isNotEmpty) {
          setState(() {
            _generatedImages.add(response.images.first);
          });
        }
      }

      if (_generatedImages.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to generate images. Please try again.';
        });
        agentService.addMessage(
          "I encountered an issue generating the images. Let's try again.",
          isFromAgent: true,
        );
      } else {
        agentService.addMessage(
          "Your images are ready! Now, select up to 3 images that you'd like to include in your story.",
          isFromAgent: true,
        );
      }
    } catch (e) {
      logger.log('Error: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
      agentService.addMessage(
        "I encountered an error: ${e.toString()}. Let's try again.",
        isFromAgent: true,
      );
    } finally {
      setState(() {
        _isGeneratingImages = false;
      });
    }
  }

  // Generate creative prompts that simulate Gemini's creative abilities
  Future<List<String>> _generateCreativePrompts() async {
    // Themes to make our prompts more creative and dynamic
    final themes = [
      'fantasy',
      'sci-fi',
      'steampunk',
      'cyberpunk',
      'magical realism',
      'fairy tale',
      'post-apocalyptic',
      'historical',
      'mythological',
      'underwater',
      'space',
    ];

    // Subjects that can be modified by themes
    final subjects = [
      'city',
      'forest',
      'castle',
      'island',
      'creature',
      'character',
      'vehicle',
      'building',
      'landscape',
      'portal',
    ];

    // Adjectives to add variety
    final adjectives = [
      'ancient',
      'futuristic',
      'mysterious',
      'enchanted',
      'haunted',
      'vibrant',
      'crystalline',
      'mechanical',
      'ethereal',
      'giant',
      'miniature',
      'floating',
      'underwater',
      'forgotten',
      'sacred',
    ];

    // Actions or states to create more dynamic scenes
    final actions = [
      'exploring',
      'transforming',
      'battling',
      'discovering',
      'awakening',
      'evolving',
      'celebrating',
      'creating',
      'defending',
      'journeying',
    ];

    // Elements to add to scenes
    final elements = [
      'mist',
      'light',
      'shadows',
      'storms',
      'flames',
      'water',
      'lightning',
      'snow',
      'magic',
      'technology',
      'plants',
      'crystals',
      'ruins',
      'portals',
      'monuments',
    ];

    // Time periods or times of day
    final times = [
      'dawn',
      'dusk',
      'night',
      'ancient times',
      'future',
      'during a storm',
      'at sunset',
      'during winter',
      'during a celebration',
      'in a parallel dimension',
    ];

    final random = Random();
    final selectedPrompts = <String>[];

    while (selectedPrompts.length < 4) {
      // Create a random combination of elements for a creative prompt
      final theme = themes[random.nextInt(themes.length)];
      final subject = subjects[random.nextInt(subjects.length)];
      final adjective = adjectives[random.nextInt(adjectives.length)];
      final action = actions[random.nextInt(actions.length)];
      final element = elements[random.nextInt(elements.length)];
      final time = times[random.nextInt(times.length)];

      // Construct prompt variations
      final promptVariations = [
        'A $adjective $theme $subject surrounded by $element $time',
        'A $subject $action in a $adjective $theme world with $element',
        '$adjective $subject from a $theme realm $action $time',
        'A scene of a $theme $subject $action through $element $time',
      ];

      final prompt = promptVariations[random.nextInt(promptVariations.length)];

      // Ensure we don't have duplicate prompts
      if (!selectedPrompts.contains(prompt)) {
        selectedPrompts.add(prompt);
      }
    }

    return selectedPrompts;
  }

  // Toggle image selection
  void _toggleImageSelection(int index) {
    final agentService = Provider.of<AgentService>(context, listen: false);

    setState(() {
      if (_selectedImageIndices.contains(index)) {
        _selectedImageIndices.remove(index);
        agentService.addMessage(
          "You removed an image from your selection.",
          isFromAgent: true,
        );
      } else {
        // Only allow selecting up to 3 images
        if (_selectedImageIndices.length < 3) {
          _selectedImageIndices.add(index);
          if (_selectedImageIndices.length == 1) {
            agentService.addMessage(
              "Great choice! You can select up to 3 images.",
              isFromAgent: true,
            );
          } else if (_selectedImageIndices.length == 3) {
            agentService.addMessage(
              "You've selected 3 images. Ready to generate your story!",
              isFromAgent: true,
            );
          }
        } else {
          // Show snackbar if user tries to select more than 3
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select a maximum of 3 images'),
              duration: Duration(seconds: 2),
            ),
          );
          agentService.addMessage(
            "You can only select up to 3 images. Deselect one if you'd like to change your selection.",
            isFromAgent: true,
          );
        }
      }
    });
  }

  // Generate story based on selected images
  Future<void> _generateStory() async {
    final agentService = Provider.of<AgentService>(context, listen: false);

    if (_selectedImageIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          duration: Duration(seconds: 2),
        ),
      );
      agentService.addMessage(
        "Please select at least one image to create a story.",
        isFromAgent: true,
      );
      return;
    }

    // Change agent role to story assistant
    agentService.changeRole(AgentRole.storyAssistant);
    agentService.addMessage(
      "I'll create a story based on your selected images. Give me a moment...",
      isFromAgent: true,
    );

    setState(() {
      _isGeneratingStory = true;
      _errorMessage = null;
      _generatedStory = null;
    });

    try {
      // Get selected prompts based on selected image indices
      final selectedPrompts =
          _selectedImageIndices
              .map((index) => _generatedPrompts[index])
              .toList();

      // Get selected images
      final selectedImages =
          _selectedImageIndices
              .map((index) => _generatedImages[index])
              .toList();

      agentService.updateContext({
        'selectedPrompts': selectedPrompts,
        'numSelectedImages': _selectedImageIndices.length,
      });

      // Create a detailed prompt for Gemini
      final prompt = _buildStoryPrompt(selectedPrompts);

      // Generate story using AgentService
      final story = await agentService.generateStory(prompt, selectedImages);

      // Count the words in the generated story
      final wordCount = story.split(RegExp(r'\s+')).length;
      logger.log('Generated story with $wordCount words');

      setState(() {
        _generatedStory = story;
      });

      // Add word count to the context
      agentService.updateContext({'storyWordCount': wordCount});

      // Switch to editor role after story is generated
      agentService.changeRole(AgentRole.editor);
      agentService.addMessage(
        "Your $wordCount-word story is ready! Here are some ways you could enhance it:",
        isFromAgent: true,
      );

      // Analyze story and provide feedback
      final feedback = await agentService.analyzeStory(story);
      agentService.addMessage(feedback, isFromAgent: true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating story: ${e.toString()}';
      });
      agentService.addMessage(
        "I encountered an error while generating your story. Let's try again.",
        isFromAgent: true,
      );
    } finally {
      setState(() {
        _isGeneratingStory = false;
      });
    }
  }

  // Helper method to build a structured prompt for Gemini
  String _buildStoryPrompt(List<String> selectedPrompts) {
    final promptThemes = selectedPrompts.join('\n- ');

    return '''
You are a creative story writer. Create an engaging, well-structured story based on the following visual themes:

- $promptThemes

Guidelines:
- Create a captivating title for the story
- The story should have a clear beginning, middle, and end
- Include rich descriptions and engaging dialogue
- Create memorable characters with clear motivations
- Include 2-3 plot twists or surprises
- The story should be 1500-2000 words
- Format with Markdown headings for chapters
- End with a satisfying conclusion

Make the story creative, engaging, and suitable for all ages. Do not include explicit violence or adult content.
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Help button that triggers agent suggestion
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              final agentService = Provider.of<AgentService>(
                context,
                listen: false,
              );
              agentService.changeRole(AgentRole.storyAssistant);
              agentService.getSuggestion();
            },
            tooltip: 'Get help from AI assistant',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step 1: Generate Images Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.deepPurple.shade100,
                                child: const Text(
                                  '1',
                                  style: TextStyle(color: Colors.deepPurple),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Generate Images',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Click the button below to generate 4 AI images using Gemini-powered creative prompts.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isGeneratingImages ? null : _generateImages,
                              icon: const Icon(Icons.image),
                              label:
                                  _isGeneratingImages
                                      ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text('Generating with Gemini...'),
                                        ],
                                      )
                                      : const Text('Generate with Gemini'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Step 2: Select Images Card
                  if (_generatedImages.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: const Text(
                                    '2',
                                    style: TextStyle(color: Colors.deepPurple),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Select Images',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Select up to 3 images to include in your story.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: _generatedImages.length,
                              itemBuilder: (context, index) {
                                final isSelected = _selectedImageIndices
                                    .contains(index);

                                return GestureDetector(
                                  onTap: () => _toggleImageSelection(index),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: Image.memory(
                                                _generatedImages[index]
                                                    .bytesBase64Encoded,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            // Show the prompt used for this image
                                            if (index <
                                                _generatedPrompts.length)
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                color: Colors.black.withOpacity(
                                                  0.7,
                                                ),
                                                width: double.infinity,
                                                child: Text(
                                                  _generatedPrompts[index],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Selection indicator
                                      if (isSelected)
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.deepPurple,
                                              width: 3,
                                            ),
                                          ),
                                        ),

                                      // Checkbox for selection
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Colors.deepPurple
                                                    : Colors.white.withOpacity(
                                                      0.7,
                                                    ),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child:
                                              isSelected
                                                  ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 20,
                                                  )
                                                  : const Icon(
                                                    Icons.add,
                                                    color: Colors.deepPurple,
                                                    size: 20,
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_generatedImages.isNotEmpty) const SizedBox(height: 20),

                  // Step 3: Generate Story Card
                  if (_generatedImages.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.deepPurple.shade100,
                                  child: const Text(
                                    '3',
                                    style: TextStyle(color: Colors.deepPurple),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Generate Story',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Generate a story based on your selected images (${_selectedImageIndices.length}/3 selected).',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isGeneratingStory ||
                                            _selectedImageIndices.isEmpty
                                        ? null
                                        : _generateStory,
                                icon: const Icon(Icons.auto_stories),
                                label:
                                    _isGeneratingStory
                                        ? const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Creating story...'),
                                          ],
                                        )
                                        : const Text('Create Story'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  disabledBackgroundColor: Colors.deepPurple
                                      .withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Generated story display
                  if (_generatedStory != null) ...[
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        const Text(
                          'Your Story',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${_generatedStory!.split(RegExp(r'\s+')).length} words',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Display selected images
                    if (_selectedImageIndices.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              _selectedImageIndices.map((index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _generatedImages[index]
                                          .bytesBase64Encoded,
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Story text
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.deepPurple.shade200),
                      ),
                      child: MarkdownBody(
                        data: _generatedStory!,
                        styleSheet: MarkdownStyleSheet(
                          a: Theme.of(
                            context,
                          ).textTheme.bodyLarge!.copyWith(color: Colors.amber),
                          blockquote: Theme.of(context).textTheme.bodyLarge,
                          checkbox: Theme.of(context).textTheme.bodyLarge,
                          code: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          del: Theme.of(context).textTheme.bodyLarge,
                          em: Theme.of(context).textTheme.bodyLarge,
                          h1: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          h2: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          h3: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          h4: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          h5: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          h6: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          img: Theme.of(context).textTheme.bodyLarge,
                          listBullet: Theme.of(context).textTheme.bodyLarge,
                          p: Theme.of(context).textTheme.bodyLarge,
                          strong: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(fontWeight: FontWeight.w600),
                          tableBody: Theme.of(context).textTheme.bodyLarge,
                          tableHead: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Share button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implement sharing functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sharing functionality coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share this story'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
          ),

          // Agent assistant widget
          SafeArea(child: const AgentAssistant()),
        ],
      ),
    );
  }
}
