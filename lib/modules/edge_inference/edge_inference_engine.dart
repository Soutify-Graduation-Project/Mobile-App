import 'dart:io';

import 'package:tflite_flutter/tflite_flutter.dart';

import 'adapter_store.dart';

class EdgeInferenceEngine {
  EdgeInferenceEngine({AdapterStore? adapterStore})
      : _adapterStore = adapterStore ?? AdapterStore();

  final AdapterStore _adapterStore;
  Interpreter? _interpreter;

  Future<void> loadBaseModel(String assetPath) async {
    _interpreter?.close();
    _interpreter = await Interpreter.fromAsset(assetPath);
  }

  /// Apply adapter weights from disk into the loaded base model.
  Future<void> attachUserAdapter() async {
    final file = await _adapterStore.activeAdapterFile();
    if (!await file.exists()) {
      // No personalization yet — run base model only.
      return;
    }
    // TODO: read [file] and inject tensors
  }

  /// Ensures [audioFilePath] exists, then runs one forward pass on the loaded
  /// model. Feature extraction from the recorded file is not implemented yet;
  /// inputs are zero-filled to match each input tensor (graph still executes).
  Future<void> runInferenceOnRecording(String audioFilePath) async {
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw StateError('Recording file not found: $audioFilePath');
    }

    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Call loadBaseModel before runInferenceOnRecording.');
    }

    await attachUserAdapter();

    final inputTensors = interpreter.getInputTensors();
    final inputs = <Object>[
      for (final t in inputTensors) _zeroBufferForTensor(t),
    ];

    final outputTensors = interpreter.getOutputTensors();
    final outputMap = <int, Object>{
      for (var i = 0; i < outputTensors.length; i++)
        i: _zeroBufferForTensor(outputTensors[i]),
    };

    interpreter.runForMultipleInputs(inputs, outputMap);
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }
}

Object _zeroBufferForTensor(Tensor t) {
  for (final d in t.shape) {
    if (d < 0) {
      throw UnsupportedError(
        'Input "${t.name}" has a dynamic dimension ($d). Resize inputs before '
        'inference, then fill from decoded audio.',
      );
    }
  }
  return _nestedZeros(t.shape, t.type);
}

Object _nestedZeros(List<int> shape, TensorType type) {
  if (shape.isEmpty) {
    return _zeroValue(type);
  }
  if (shape.length == 1) {
    return List<Object>.generate(shape[0], (_) => _zeroValue(type));
  }
  return List<Object>.generate(
    shape[0],
    (_) => _nestedZeros(shape.sublist(1), type),
  );
}

Object _zeroValue(TensorType type) {
  switch (type) {
    case TensorType.float32:
    case TensorType.float16:
    case TensorType.float64:
      return 0.0;
    case TensorType.int32:
    case TensorType.uint8:
    case TensorType.int8:
    case TensorType.int16:
    case TensorType.uint32:
    case TensorType.uint16:
    case TensorType.int4:
    case TensorType.uint64:
    case TensorType.int64:
      return 0;
    case TensorType.boolean:
      return false;
    case TensorType.noType:
    case TensorType.string:
    case TensorType.complex64:
    case TensorType.complex128:
    case TensorType.resource:
    case TensorType.variant:
      throw UnsupportedError(
        'Tensor type $type is not supported for zero-filled inference.',
      );
  }
}
