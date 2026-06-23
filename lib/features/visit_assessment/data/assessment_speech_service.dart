import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AssessmentSpeechService {
  AssessmentSpeechService._();

  static final AssessmentSpeechService instance = AssessmentSpeechService._();
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> start(ValueChanged<String> onWords) async {
    if (!_initialized) {
      _initialized = await _speech.initialize();
    }
    if (!_initialized) return false;
    await _speech.listen(
      onResult: (result) => onWords(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
    return true;
  }

  Future<void> stop() => _speech.stop();
}
