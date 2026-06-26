import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AssessmentSpeechService {
  AssessmentSpeechService._();

  static final AssessmentSpeechService instance = AssessmentSpeechService._();
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  List<LocaleName>? _locales;

  bool get isListening => _speech.isListening;

  Future<bool> start(
    ValueChanged<String> onWords, {
    String? preferredLocaleId,
  }) async {
    if (!_initialized) {
      _initialized = await _speech.initialize();
    }
    if (!_initialized) return false;
    final localeId = await _resolveLocaleId(preferredLocaleId);
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (result.finalResult && words.isNotEmpty) {
          onWords(words);
        }
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        localeId: localeId,
      ),
    );
    return true;
  }

  Future<void> stop() => _speech.stop();

  Future<String?> _resolveLocaleId(String? preferredLocaleId) async {
    final preferred = preferredLocaleId?.trim();
    if (preferred == null || preferred.isEmpty) return null;
    try {
      _locales ??= await _speech.locales();
      final normalizedPreferred = _normalizeLocale(preferred);
      for (final locale in _locales!) {
        if (_normalizeLocale(locale.localeId) == normalizedPreferred) {
          return locale.localeId;
        }
      }

      final preferredLanguage = normalizedPreferred.split('_').first;
      for (final locale in _locales!) {
        if (_normalizeLocale(locale.localeId).split('_').first ==
            preferredLanguage) {
          return locale.localeId;
        }
      }
    } catch (_) {
      return preferred;
    }
    return null;
  }

  String _normalizeLocale(String value) =>
      value.trim().replaceAll('-', '_').toLowerCase();
}
