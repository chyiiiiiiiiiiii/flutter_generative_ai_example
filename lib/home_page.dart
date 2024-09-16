import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

enum InteractionMode {
  normal,
  stream;

  bool get isNormal => this == InteractionMode.normal;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: const String.fromEnvironment('AI_API_KEY'),
  );

  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  InteractionMode _interactionMode = InteractionMode.normal;
  String _responseText = '';
  StreamSubscription<GenerateContentResponse>? _responseStreamSubscription;
  final StreamController<String> _responseStreamController =
      StreamController<String>.broadcast();

  Future<void> _generateResponse({
    required String prompt,
  }) async {
    try {
      setState(() {
        _interactionMode = InteractionMode.normal;
        _responseText = '';
      });

      final content = [Content.text(prompt)];

      final response = await model.generateContent(content);
      setState(() {
        _responseText = response.text ?? '';
      });

      _scrollDown();
    } catch (e) {
      debugPrint('Error - failed to generate text: $e');
    }
  }

  Future<void> _generateResponseStream({
    required String prompt,
  }) async {
    try {
      _responseStreamSubscription?.cancel();

      setState(() {
        _interactionMode = InteractionMode.stream;
      });
      _responseText = '';
      _responseStreamController.add('');

      final content = [Content.text(prompt)];

      _responseStreamSubscription =
          model.generateContentStream(content).listen((response) {
        final newText = _responseText + (response.text ?? '');
        _responseText = newText;
        _responseStreamController.add(newText);

        _scrollDown();
      });
    } catch (e) {
      debugPrint('Error - failed to generate text: $e');
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _responseStreamSubscription?.cancel();
    _responseStreamController.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Generative AI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              TextField(
                controller: _inputController,
                decoration: const InputDecoration(
                  labelText: 'Enter a prompt',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () =>
                        _generateResponse(prompt: _inputController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Get Response'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _generateResponseStream(
                      prompt: _inputController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Get Stream Response'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _interactionMode.isNormal
                      ? Text(
                          _responseText,
                        )
                      : StreamBuilder(
                          stream: _responseStreamController.stream,
                          builder: (context, snapshot) {
                            final text = snapshot.data ?? '';

                            return Text(
                              text,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
