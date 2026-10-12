import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Robust Speech-To-Text and Text-To-Speech Audio Service with graceful platform fallback.
class SpeechVoiceService {
  SpeechVoiceService._();
  static final SpeechVoiceService instance = SpeechVoiceService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  bool _isListening = false;
  bool _isSpeechAvailableOnDevice = false;

  bool get isListening => _isListening;
  bool get isSpeechAvailable => _isSpeechAvailableOnDevice;

  /// Initialize Speech Recognition and TTS Engine
  Future<bool> initialize() async {
    // 1. Initialize TTS Engine
    if (!_isTtsInitialized) {
      try {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.awaitSynthCompletion(true);
        _isTtsInitialized = true;
      } catch (e) {
        debugPrint('[SpeechVoiceService] TTS init note: $e');
      }
    }

    // 2. Initialize Hardware Speech Recognition
    if (!_isSpeechInitialized) {
      try {
        _isSpeechAvailableOnDevice = await _speech.initialize(
          onStatus: (status) {
            debugPrint('[SpeechVoiceService] Status: $status');
            if (status == 'done' || status == 'notListening') {
              _isListening = false;
            }
          },
          onError: (SpeechRecognitionError error) {
            debugPrint('[SpeechVoiceService] Error: ${error.errorMsg}');
            _isListening = false;
          },
          debugLogging: false,
        );
        _isSpeechInitialized = true;
      } catch (e) {
        debugPrint('[SpeechVoiceService] STT init note (will use fallback): $e');
        _isSpeechAvailableOnDevice = false;
        _isSpeechInitialized = true; // Mark as attempted
      }
    }

    return _isSpeechAvailableOnDevice;
  }

  /// Start recording voice from device microphone with automatic error recovery
  Future<bool> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    Function(double soundLevel)? onSoundLevelChange,
    VoidCallback? onError,
  }) async {
    await stopSpeaking();

    if (!_isSpeechInitialized) {
      await initialize();
    }

    if (!_isSpeechAvailableOnDevice) {
      _isListening = false;
      onError?.call();
      return false;
    }

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }

      _isListening = true;

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords, result.finalResult);
        },
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
          localeId: 'en_US',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[SpeechVoiceService] Listen exception: $e');
      _isListening = false;
      onError?.call();
      return false;
    }
  }

  /// Stop listening to microphone
  Future<void> stopListening() async {
    _isListening = false;
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
  }

  /// Speak response text using Text-to-Speech
  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    try {
      await stopListening();
      await _flutterTts.stop();

      // Clean markdown characters from spoken text
      final cleanText = text
          .replaceAll(RegExp(r'[*#_`~]'), '')
          .replaceAll('•', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleanText.isEmpty) {
        onComplete?.call();
        return;
      }

      if (onComplete != null) {
        _flutterTts.setCompletionHandler(() {
          onComplete();
        });
      }

      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('[SpeechVoiceService] Speak error: $e');
      onComplete?.call();
    }
  }

  /// Stop ongoing speech playback
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
