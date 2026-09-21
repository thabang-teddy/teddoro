// Generates the alarm and ambient WAV assets procedurally so the repo has no
// third-party audio. Run from the app folder:
//
//   dart run tool/gen_sounds.dart
//
// Alarms are short one-shots; ambient beds are 10 s loops whose tail is
// cross-faded into the head so they repeat seamlessly.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const sampleRate = 16000;
const outDir = 'assets/sounds';

void main() {
  Directory(outDir).createSync(recursive: true);
  _write('alarm_bell.wav', _bell());
  _write('alarm_chime.wav', _chime());
  _write('alarm_digital.wav', _digital());
  _write('ambient_white.wav', _loop(_whiteNoise(10)));
  _write('ambient_rain.wav', _loop(_rain(10)));
  _write('ambient_cafe.wav', _loop(_cafe(10)));
  _write('ambient_ticking.wav', _loop(_ticking(10)));
  stdout.writeln('Wrote 7 files to $outDir');
}

// ---------------------------------------------------------------- alarms --

Float64List _bell() {
  final out = Float64List(sampleRate * 3);
  for (final strike in [0.0, 0.65, 1.3]) {
    _addPartial(out, strike, 880, 1.0, 1.6);
    _addPartial(out, strike, 1760, 0.45, 1.1);
    _addPartial(out, strike, 2640, 0.2, 0.7);
    _addPartial(out, strike, 3520, 0.08, 0.4);
  }
  return _normalise(out, 0.9);
}

Float64List _chime() {
  final out = Float64List(sampleRate * 3);
  const notes = [1046.5, 1318.5, 1568.0, 2093.0]; // C6 E6 G6 C7
  for (var i = 0; i < notes.length; i++) {
    _addPartial(out, i * 0.28, notes[i], 0.8, 1.4);
    _addPartial(out, i * 0.28, notes[i] * 2, 0.15, 0.6);
  }
  return _normalise(out, 0.9);
}

Float64List _digital() {
  final out = Float64List((sampleRate * 2.2).round());
  for (var i = 0; i < 5; i++) {
    final start = (i * 0.32 * sampleRate).round();
    final len = (0.16 * sampleRate).round();
    for (var n = 0; n < len; n++) {
      final t = n / sampleRate;
      // Square-ish tone with a soft edge so it isn't harsh.
      final sq = math.sin(2 * math.pi * 1000 * t) > 0 ? 1.0 : -1.0;
      final env = math.min(1.0, math.min(n, len - n) / (0.01 * sampleRate));
      out[start + n] += sq * 0.6 * env;
    }
  }
  return _normalise(out, 0.85);
}

void _addPartial(
  Float64List out,
  double startSec,
  double freq,
  double amp,
  double decaySec,
) {
  final start = (startSec * sampleRate).round();
  for (var n = start; n < out.length; n++) {
    final t = (n - start) / sampleRate;
    out[n] += amp * math.exp(-t / decaySec) * math.sin(2 * math.pi * freq * t);
  }
}

// ------------------------------------------------------------- ambients --

Float64List _whiteNoise(int seconds) {
  final rng = math.Random(1);
  final out = Float64List(sampleRate * seconds);
  for (var n = 0; n < out.length; n++) {
    out[n] = rng.nextDouble() * 2 - 1;
  }
  return _normalise(_lowPass(out, 0.6), 0.5);
}

/// Brown-ish noise bed plus sparse droplet clicks.
Float64List _rain(int seconds) {
  final rng = math.Random(2);
  final out = Float64List(sampleRate * seconds);
  var brown = 0.0;
  for (var n = 0; n < out.length; n++) {
    brown = (brown + (rng.nextDouble() * 2 - 1) * 0.08).clamp(-1.0, 1.0);
    out[n] = brown * 0.7 + (rng.nextDouble() * 2 - 1) * 0.15;
  }
  for (var i = 0; i < seconds * 25; i++) {
    final at = rng.nextInt(out.length - 200);
    final amp = 0.2 + rng.nextDouble() * 0.3;
    for (var n = 0; n < 120; n++) {
      out[at + n] += amp * math.exp(-n / 25) * (rng.nextDouble() * 2 - 1);
    }
  }
  return _normalise(_lowPass(out, 0.35), 0.6);
}

/// Low murmur: pink-ish noise with slow amplitude wobble and occasional clinks.
Float64List _cafe(int seconds) {
  final rng = math.Random(3);
  final out = Float64List(sampleRate * seconds);
  var b0 = 0.0, b1 = 0.0, b2 = 0.0;
  for (var n = 0; n < out.length; n++) {
    final white = rng.nextDouble() * 2 - 1;
    b0 = 0.99765 * b0 + white * 0.0990460;
    b1 = 0.96300 * b1 + white * 0.2965164;
    b2 = 0.57000 * b2 + white * 1.0526913;
    final pink = (b0 + b1 + b2 + white * 0.1848) * 0.12;
    final t = n / sampleRate;
    final wobble =
        0.7 +
        0.3 *
            math.sin(2 * math.pi * 0.23 * t) *
            math.sin(2 * math.pi * 0.07 * t + 1);
    out[n] = pink * wobble;
  }
  for (var i = 0; i < seconds * 2; i++) {
    final at = rng.nextInt(out.length - 2000);
    final f = 2000 + rng.nextDouble() * 2500;
    for (var n = 0; n < 1600; n++) {
      out[at + n] +=
          0.08 *
          math.exp(-n / 300) *
          math.sin(2 * math.pi * f * n / sampleRate);
    }
  }
  return _normalise(_lowPass(out, 0.25), 0.55);
}

/// One tick per second; alternate ticks are slightly lower ("tock").
Float64List _ticking(int seconds) {
  final rng = math.Random(4);
  final out = Float64List(sampleRate * seconds);
  for (var s = 0; s < seconds; s++) {
    final at = s * sampleRate;
    final f = s.isEven ? 2400.0 : 1900.0;
    for (var n = 0; n < 700; n++) {
      final t = n / sampleRate;
      final env = math.exp(-t * 90);
      out[at + n] +=
          env *
          (0.7 * math.sin(2 * math.pi * f * t) +
              0.3 * (rng.nextDouble() * 2 - 1));
    }
  }
  return _normalise(out, 0.7);
}

// ---------------------------------------------------------------- utils --

Float64List _lowPass(Float64List input, double alpha) {
  final out = Float64List(input.length);
  var y = 0.0;
  for (var n = 0; n < input.length; n++) {
    y += alpha * (input[n] - y);
    out[n] = y;
  }
  return out;
}

/// Cross-fade the last 0.5 s into the first 0.5 s so the loop is seamless.
Float64List _loop(Float64List input) {
  final fade = (0.5 * sampleRate).round();
  final len = input.length - fade;
  final out = Float64List(len);
  for (var n = 0; n < len; n++) {
    if (n < fade) {
      final t = n / fade;
      out[n] = input[n] * t + input[len + n] * (1 - t);
    } else {
      out[n] = input[n];
    }
  }
  return out;
}

Float64List _normalise(Float64List input, double peak) {
  var max = 0.0;
  for (final v in input) {
    if (v.abs() > max) max = v.abs();
  }
  if (max == 0) return input;
  final k = peak / max;
  final out = Float64List(input.length);
  for (var n = 0; n < input.length; n++) {
    out[n] = input[n] * k;
  }
  return out;
}

void _write(String name, Float64List samples) {
  final data = ByteData(samples.length * 2);
  for (var n = 0; n < samples.length; n++) {
    data.setInt16(
      n * 2,
      (samples[n].clamp(-1.0, 1.0) * 32767).round(),
      Endian.little,
    );
  }
  final header = ByteData(44)
    ..setUint32(0, 0x46464952, Endian.little) // RIFF
    ..setUint32(4, 36 + data.lengthInBytes, Endian.little)
    ..setUint32(8, 0x45564157, Endian.little) // WAVE
    ..setUint32(12, 0x20746d66, Endian.little) // fmt
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x61746164, Endian.little) // data
    ..setUint32(40, data.lengthInBytes, Endian.little);
  File('$outDir/$name').writeAsBytesSync([
    ...header.buffer.asUint8List(),
    ...data.buffer.asUint8List(),
  ]);
}
