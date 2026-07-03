// lib/models/coin_pack.dart

class CoinPack {
  final String id;
  final String productId;
  final int coins;
  final String label;
  final String? bonusLabel;

  const CoinPack({
    required this.id,
    required this.productId,
    required this.coins,
    required this.label,
    this.bonusLabel,
  });

  static const List<CoinPack> packs = [
    CoinPack(
      id: 'pack_100',
      productId: 'coins_100',
      coins: 100,
      label: '\$1.01',
    ),
    CoinPack(
      id: 'pack_200',
      productId: 'coins_200',
      coins: 200,
      label: '\$2.01',
    ),
    CoinPack(
      id: 'pack_320',
      productId: 'coins_320',
      coins: 320,
      label: '\$3.01',
      bonusLabel: '+7% BONUS',
    ),
    CoinPack(
      id: 'pack_440',
      productId: 'coins_440',
      coins: 440,
      label: '\$4.01',
      bonusLabel: '+10% BONUS',
    ),
    CoinPack(
      id: 'pack_575',
      productId: 'coins_575',
      coins: 575,
      label: '\$5.01',
      bonusLabel: '+15% BONUS',
    ),
    CoinPack(
      id: 'pack_1200',
      productId: 'coins_1200',
      coins: 1200,
      label: '\$10.01',
      bonusLabel: '+20% BONUS',
    ),
    CoinPack(
      id: 'pack_2600',
      productId: 'coins_2600',
      coins: 2600,
      label: '\$20.01',
      bonusLabel: '+30% BONUS',
    ),
    CoinPack(
      id: 'pack_3400',
      productId: 'coins_3400',
      coins: 3400,
      label: '\$25.01',
      bonusLabel: '+36% BONUS',
    ),
    CoinPack(
      id: 'pack_4200',
      productId: 'coins_4200',
      coins: 4200,
      label: '\$30.01',
      bonusLabel: '+40% BONUS',
    ),
    CoinPack(
      id: 'pack_5100',
      productId: 'coins_5100',
      coins: 5100,
      label: '\$35.01',
      bonusLabel: '+46% BONUS',
    ),
    CoinPack(
      id: 'pack_6000',
      productId: 'coins_6000',
      coins: 6000,
      label: '\$40.01',
      bonusLabel: 'BEST VALUE +50%',
    ),
  ];
}
