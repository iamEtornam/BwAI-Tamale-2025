import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:story_teller/services/agent_service.dart';

class AgentAssistant extends StatefulWidget {
  const AgentAssistant({super.key});

  @override
  State<AgentAssistant> createState() => _AgentAssistantState();
}

class _AgentAssistantState extends State<AgentAssistant>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize with a welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final agentService = Provider.of<AgentService>(context, listen: false);
      agentService.addMessage(
        "Hi! I'm your Story Teller assistant. I can help you create amazing stories. What would you like to do?",
        isFromAgent: true,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentService>(
      builder: (context, agentService, child) {
        return Stack(
          children: [
            // Expanded chat interface
            if (_isExpanded)
              Positioned(
                bottom: 80,
                right: 16,
                child: SizeTransition(
                  sizeFactor: _scaleAnimation,
                  axis: Axis.vertical,
                  axisAlignment: -1,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: 300,
                      height: 400,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Story Assistant',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Role selector dropdown
                              DropdownButton<AgentRole>(
                                value: agentService.currentRole,
                                underline: const SizedBox(),
                                items:
                                    AgentRole.values.map((role) {
                                      String roleName;
                                      switch (role) {
                                        case AgentRole.storyAssistant:
                                          roleName = 'Assistant';
                                          break;
                                        case AgentRole.imageCreator:
                                          roleName = 'Creator';
                                          break;
                                        case AgentRole.editor:
                                          roleName = 'Editor';
                                          break;
                                      }
                                      return DropdownMenuItem(
                                        value: role,
                                        child: Text(roleName),
                                      );
                                    }).toList(),
                                onChanged: (role) {
                                  if (role != null) {
                                    agentService.changeRole(role);
                                  }
                                },
                              ),
                            ],
                          ),
                          const Divider(),
                          // Chat messages
                          Expanded(
                            child: ListView.builder(
                              reverse: true,
                              itemCount: agentService.history.length,
                              itemBuilder: (context, index) {
                                final reversedIndex =
                                    agentService.history.length - 1 - index;
                                final message =
                                    agentService.history[reversedIndex];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        message.isFromAgent
                                            ? MainAxisAlignment.start
                                            : MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth: 230,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 8.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              message.isFromAgent
                                                  ? Colors.deepPurple.shade100
                                                  : Colors.deepPurple.shade500,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          message.text,
                                          style: TextStyle(
                                            color:
                                                message.isFromAgent
                                                    ? Colors.black87
                                                    : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(),
                          // Input field
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  decoration: const InputDecoration(
                                    hintText: 'Ask me anything...',
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty) {
                                      agentService.addMessage(
                                        value,
                                        isFromAgent: false,
                                      );
                                      agentService.getSuggestion(input: value);
                                      _inputController.clear();
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                color: Colors.deepPurple,
                                onPressed: () {
                                  if (_inputController.text.isNotEmpty) {
                                    agentService.addMessage(
                                      _inputController.text,
                                      isFromAgent: false,
                                    );
                                    agentService.getSuggestion(
                                      input: _inputController.text,
                                    );
                                    _inputController.clear();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.lightbulb_outline),
                                color: Colors.deepPurple,
                                onPressed: () {
                                  agentService.getSuggestion();
                                },
                                tooltip: 'Get suggestion',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Floating action button to toggle chat
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _toggleExpanded,
                backgroundColor: Colors.deepPurple,
                child: Icon(
                  _isExpanded ? Icons.close : Icons.chat_bubble,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
