/// Placeholder for amplitude normalization, resampling, and VAD hooks.
///
/// TODO: Long hangover VAD for pauses mid-word; feed normalized 16 kHz frames
/// to the edge engine.
class AudioPreprocessStub {
  /// Normalize raw PCM samples in-place or return a new buffer (TBD).
  List<double> normalizeAmplitude(List<double> samples) {
    // TODO: implement
    return samples;
  }

  /// Resample to [targetHz] if needed (TBD).
  List<double> resample({
    required List<double> samples,
    required int sourceHz,
    required int targetHz,
  }) {
    // TODO: implement
    return samples;
  }
}
