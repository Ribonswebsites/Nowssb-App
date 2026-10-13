/// Page-local models for Signature Words. Swap for the shared
/// CatalogRepository (Bug Hunter's data layer) when it lands on main.
library;

enum Rarity { common, rare, epic, legendary }

extension RarityX on Rarity {
  String get label => const ['Common', 'Rare', 'Epic', 'Legendary'][index];
}

class SignatureWord {
  const SignatureWord({
    required this.id,
    required this.word,
    required this.sound,
    required this.rarity,
    required this.priceCoins,
    this.locked = false,
    this.dropAt,
    this.owned = false,
  });
  final String id;
  final String word;
  /// Short "described by sound" line.
  final String sound;
  final Rarity rarity;
  final int priceCoins;
  /// Upcoming drop: shown with a padlock, not buyable.
  final bool locked;
  final DateTime? dropAt;
  final bool owned;
}

class OfflineException implements Exception {
  const OfflineException();
}

abstract class SignatureSource {
  Future<List<SignatureWord>> load();
}

/// Demo data until the shared catalog exists.
class DemoSignatureSource implements SignatureSource {
  const DemoSignatureSource();
  @override
  Future<List<SignatureWord>> load() async => [
        const SignatureWord(id: 'aum', word: 'Aum', sound: 'A low hum that opens like a bell', rarity: Rarity.legendary, priceCoins: 900),
        const SignatureWord(id: 'shanti', word: 'Shanti', sound: 'Soft breath, then stillness', rarity: Rarity.epic, priceCoins: 600, owned: true),
        const SignatureWord(id: 'lumen', word: 'Lumen', sound: 'Bright, round, like light on water', rarity: Rarity.rare, priceCoins: 350),
        const SignatureWord(id: 'sora', word: 'Sora', sound: 'An open sky in two notes', rarity: Rarity.common, priceCoins: 150),
        SignatureWord(id: 'velora', word: 'Velora', sound: 'Coming soon', rarity: Rarity.legendary, priceCoins: 1200, locked: true, dropAt: DateTime(2026, 11, 1)),
      ];
}
