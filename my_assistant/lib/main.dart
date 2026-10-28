import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:torch_light/torch_light.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VoiceAssistantScreen(),
  ));
}

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  String _spokenText = "Batone chap diye kotha bolun...";
  String _botResponse = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _requestInitialPermissions();
  }

  Future<void> _requestInitialPermissions() async {
    await [
      Permission.microphone,
      Permission.phone,
      Permission.camera,
    ].request();
  }

  Future<void> _speak(String message) async {
    setState(() => _botResponse = message);
    await _tts.speak(message);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _spokenText = result.recognizedWords;
            });
            if (result.finalResult) {
              _processCommand(_spokenText.toLowerCase());
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _processCommand(String command) async {
    if (command.contains("torch on") || command.contains("light on")) {
      try {
        await TorchLight.enableTorch();
        _speak("Flashlight jwelechi.");
      } catch (e) {
        _speak("Torch jwalano jayni.");
      }
    } else if (command.contains("torch off") || command.contains("light off")) {
      try {
        await TorchLight.disableTorch();
        _speak("Flashlight bondho korechi.");
      } catch (e) {
        _speak("Torch bondho kora jayni.");
      }
    } else if (command.contains("play") || command.contains("gaan") || command.contains("youtube")) {
      String query = command
          .replaceAll("play", "")
          .replaceAll("youtube", "")
          .replaceAll("gaan", "")
          .trim();
      final Uri url = Uri.parse("https://www.youtube.com/results?search_query=$query");
      _speak("YouTube-e khujchi.");
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (command.contains("call")) {
      final Uri phoneUri = Uri(scheme: 'tel', path: '198');
      _speak("Call korchi.");
      await launchUrl(phoneUri);
    } else if (command.contains("time") || command.contains("shomoy")) {
      DateTime now = DateTime.now();
      String timeStr = "${now.hour} ta ${now.minute} minute";
      _speak("Ekhon shomoy $timeStr.");
    } else {
      _speak("Ami command-ti bujhte parini. Abar bolun.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("My Personal Voice Assistant"),
        backgroundColor: const Color(0xFF1F1F1F),
        centerTitle: true,
      ),
      body: Padding(
        padding: const patriotic,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Tumi bolechho:",
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "\"$_spokenText\"",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Text(
              "Assistant-er Uttor:",
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _botResponse,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Center(
              child: GestureDetector(
                onTap: _listen,
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: _isListening ? Colors.redAccent : Colors.cyan,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isListening ? "Shunchi..." : "Mic-e chap diye command bolun",
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}cd /workspaces/voice-assistant && mkdir -p .github/workflows && cat << 'EOF' > .github/workflows/build.yml
name: Build Android APK

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Build APK
        run: |
          cd my_assistant
          flutter pub get
          flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: voice-assistant-apk
          path: my_assistant/build/app/outputs/flutter-apk/app-release.apk
EOF
