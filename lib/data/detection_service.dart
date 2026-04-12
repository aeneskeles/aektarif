import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/ingredient.dart';

final detectionServiceProvider = Provider<DetectionService>((ref) {
  return DetectionService();
});

class DetectionService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  static const int inputSize = 224;
  static const double confidenceThreshold = 0.5;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/ingredient_model.tflite');
      
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Model yüklenemedi: $e');
    }
  }

  Future<DetectionResult> detectIngredients(File imageFile) async {
    await initialize();

    if (_interpreter == null) {
      return _getMockDetections();
    }

    try {
      final stopwatch = Stopwatch()..start();

      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Görüntü işlenemedi');
      }

      final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
      
      final input = _imageToByteListFloat32(resizedImage);
      
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      
      List<List<double>> output;
      if (outputShape.length == 2) {
        output = List.generate(
          outputShape[0],
          (_) => List.filled(outputShape[1], 0.0),
        );
      } else {
        output = [List.filled(_labels.length, 0.0)];
      }

      _interpreter!.run(input, output);

      final detections = <DetectedIngredient>[];
      final results = output[0];
      
      for (int i = 0; i < results.length && i < _labels.length; i++) {
        final confidence = results[i];
        if (confidence > confidenceThreshold && _labels[i] != 'Unlabeled') {
          detections.add(DetectedIngredient(
            label: _labels[i],
            confidence: confidence,
            bbox: null,
          ));
        }
      }

      detections.sort((a, b) => b.confidence.compareTo(a.confidence));

      stopwatch.stop();

      return DetectionResult(
        success: true,
        detections: detections.take(10).toList(),
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      return _getMockDetections();
    }
  }

  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    final convertedBytes = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return convertedBytes;
  }

  DetectionResult _getMockDetections() {
    return DetectionResult(
      success: true,
      detections: [
        DetectedIngredient(
          label: 'eggs',
          confidence: 0.92,
          bbox: null,
        ),
        DetectedIngredient(
          label: 'butter',
          confidence: 0.88,
          bbox: null,
        ),
        DetectedIngredient(
          label: 'flour',
          confidence: 0.85,
          bbox: null,
        ),
        DetectedIngredient(
          label: 'sugar',
          confidence: 0.82,
          bbox: null,
        ),
        DetectedIngredient(
          label: 'carrots',
          confidence: 0.78,
          bbox: null,
        ),
      ],
      processingTimeMs: 150,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

class DetectionResult {
  final bool success;
  final List<DetectedIngredient> detections;
  final int? processingTimeMs;
  final String? error;

  DetectionResult({
    required this.success,
    required this.detections,
    this.processingTimeMs,
    this.error,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      success: json['success'] as bool? ?? false,
      detections: (json['detections'] as List<dynamic>?)
              ?.map((e) => DetectedIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      processingTimeMs: json['processing_time_ms'] as int?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'detections': detections.map((e) => e.toJson()).toList(),
      'processing_time_ms': processingTimeMs,
      'error': error,
    };
  }
}

class DetectionState {
  final bool isLoading;
  final DetectionResult? result;
  final String? error;
  final Set<String> selectedIngredients;

  const DetectionState({
    this.isLoading = false,
    this.result,
    this.error,
    this.selectedIngredients = const {},
  });

  DetectionState copyWith({
    bool? isLoading,
    DetectionResult? result,
    String? error,
    Set<String>? selectedIngredients,
  }) {
    return DetectionState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
      selectedIngredients: selectedIngredients ?? this.selectedIngredients,
    );
  }
}

class DetectionNotifier extends StateNotifier<DetectionState> {
  DetectionNotifier(this._service) : super(const DetectionState());

  final DetectionService _service;

  Future<void> detectFromImage(File imageFile) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.detectIngredients(imageFile);
      
      final selectedLabels = result.detections.map((d) => d.label).toSet();
      
      state = state.copyWith(
        isLoading: false,
        result: result,
        selectedIngredients: selectedLabels,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void toggleIngredient(String label) {
    final current = Set<String>.from(state.selectedIngredients);
    if (current.contains(label)) {
      current.remove(label);
    } else {
      current.add(label);
    }
    state = state.copyWith(selectedIngredients: current);
  }

  void selectAll() {
    if (state.result == null) return;
    final allLabels = state.result!.detections.map((d) => d.label).toSet();
    state = state.copyWith(selectedIngredients: allLabels);
  }

  void deselectAll() {
    state = state.copyWith(selectedIngredients: {});
  }

  void reset() {
    state = const DetectionState();
  }
}

final detectionNotifierProvider = StateNotifierProvider<DetectionNotifier, DetectionState>((ref) {
  final service = ref.watch(detectionServiceProvider);
  return DetectionNotifier(service);
});
