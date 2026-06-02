// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:llm_meter/llm_meter.dart';

void main() {
  LlmMeter.init(const MeterConfig(
    sinks: <MeterSink>[ConsoleSink()],
  ));
  runApp(const LlmMeterDemoApp());
}

class LlmMeterDemoApp extends StatelessWidget {
  const LlmMeterDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'llm_meter demo',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E1116),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E1116),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const ChatPage(),
    );
  }
}

class _Msg {
  _Msg({
    required this.role,
    required this.model,
    required this.text,
    this.streaming = false,
  });
  final String role;
  final String model;
  String text;
  bool streaming;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<_Msg> _messages = <_Msg>[];
  final ScrollController _scroll = ScrollController();
  bool _running = false;
  Timer? _autoTimer;

  static const List<String> _demoModels = <String>[
    'gpt-5',
    'gpt-5-mini',
    'claude-sonnet-4-6',
    'claude-opus-4-7',
    'gemini-2.5-pro',
    'gemini-2.5-flash',
    'llama-3.3-70b',
    'deepseek-v3',
  ];

  static const List<String> _prompts = <String>[
    'Summarize this PR in 2 sentences.',
    'Explain Erlang virtual machine pinning to a Dart developer.',
    'Refactor this function for readability.',
    'Translate to Swedish, then back to English, compare deltas.',
    'Why does Sweden have a high Spotify density?',
    'Write a haiku about token billing.',
  ];

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendOne() async {
    final Random rng = Random();
    final String model = _demoModels[rng.nextInt(_demoModels.length)];
    final String prompt = _prompts[rng.nextInt(_prompts.length)];
    final int promptTokens = 400 + rng.nextInt(1600);
    final int responseTokens = 80 + rng.nextInt(420);
    final int cachedTokens =
        rng.nextDouble() < 0.4 ? (promptTokens * 0.7).round() : 0;

    setState(() {
      _messages.add(_Msg(role: 'user', model: model, text: prompt));
      _messages.add(_Msg(role: 'assistant', model: model, text: '', streaming: true));
    });
    _scrollToBottom();

    final Stream<String> source = _fakeStream(
      model: model,
      tokens: responseTokens,
    );
    final Stream<String> metered = MeteredStream.wrap<String>(
      provider: _providerFor(model),
      model: model,
      stream: source,
      // Pretend the final chunk carries usage info.
      extractChunk: (String chunk) => chunk == '<<END>>'
          ? MeterUsage(
              tokensIn: promptTokens - cachedTokens,
              tokensOut: responseTokens,
              cachedTokensIn: cachedTokens,
            )
          : null,
    );

    await for (final String chunk in metered) {
      if (chunk == '<<END>>') continue;
      setState(() {
        _messages.last.text += chunk;
      });
      _scrollToBottom();
    }
    setState(() {
      _messages.last.streaming = false;
    });
  }

  void _toggleAuto() {
    setState(() => _running = !_running);
    if (_running) {
      _autoTimer = Timer.periodic(const Duration(milliseconds: 1800),
          (_) => unawaited(_sendOne()));
      unawaited(_sendOne());
    } else {
      _autoTimer?.cancel();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('llm_meter demo'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear chat + meter',
            onPressed: () {
              LlmMeter.instance.clear();
              setState(_messages.clear);
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int i) =>
                      _MsgBubble(msg: _messages[i]),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _running ? null : _sendOne,
                          icon: const Icon(Icons.send),
                          label: const Text('Send one'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: _toggleAuto,
                        icon: Icon(_running
                            ? Icons.stop_circle
                            : Icons.play_circle_fill),
                        label: Text(_running ? 'Stop auto' : 'Auto-run'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Positioned.fill(child: LlmMeterHud()),
        ],
      ),
    );
  }
}

class _MsgBubble extends StatelessWidget {
  const _MsgBubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final bool me = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: me ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: me ? const Color(0xFF1F6FEB) : const Color(0xFF1B2128),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment:
                  me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  msg.model,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.text.isEmpty && msg.streaming ? '…' : msg.text,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _providerFor(String model) {
  if (model.startsWith('gpt') || model.startsWith('o')) return 'openai';
  if (model.startsWith('claude')) return 'anthropic';
  if (model.startsWith('gemini')) return 'gemini';
  if (model.startsWith('llama')) return 'meta';
  if (model.startsWith('deepseek')) return 'deepseek';
  return 'unknown';
}

Stream<String> _fakeStream({
  required String model,
  required int tokens,
}) async* {
  final Random rng = Random();
  // Per-token latency varies by model class.
  final int perTokenMs = model.contains('opus') || model.contains('pro')
      ? 18
      : model.contains('mini') || model.contains('flash') || model.contains('nano')
          ? 6
          : 10;

  const String text =
      'OK — drafting a reply on the fly. The HUD on the right tracks '
      'cost + latency + cache % per call. Each variant of model is billed '
      'differently; the bundled pricing table maps the top 30 hosted models. ';

  int emitted = 0;
  while (emitted < tokens) {
    final int chunkLen = 6 + rng.nextInt(12);
    final int end = (emitted + chunkLen).clamp(0, tokens);
    final String chunk =
        text.substring(emitted % text.length, ((end - 1) % text.length) + 1);
    yield chunk;
    await Future<void>.delayed(Duration(milliseconds: perTokenMs * chunkLen));
    emitted = end;
  }
  yield '<<END>>';
}
