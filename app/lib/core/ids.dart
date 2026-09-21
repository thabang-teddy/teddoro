import 'dart:math';

/// Generates collision-resistant ids without a dependency. Time prefix keeps
/// ids roughly sortable, which will help a future sync layer.
class IdGenerator {
  IdGenerator([Random? random]) : _random = random ?? Random.secure();

  final Random _random;
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  String next() {
    final time = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final tail = List.generate(
      8,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();
    return '$time-$tail';
  }
}
