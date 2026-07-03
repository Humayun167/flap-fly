// lib/screens/coin_shop_screen.dart
import 'package:flutter/material.dart';
import '../models/coin_pack.dart';
import '../services/purchase_service.dart';

class CoinShopScreen extends StatefulWidget {
  final int currentCoins;

  const CoinShopScreen({
    super.key,
    required this.currentCoins,
  });

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  int _displayCoins = 0;

  // Save original callbacks to restore on dispose
  void Function(int coins)? _originalOnCoinsDelivered;
  void Function(String message)? _originalOnError;
  void Function()? _originalOnStateChanged;

  @override
  void initState() {
    super.initState();
    _displayCoins = widget.currentCoins;

    // Save original callbacks
    _originalOnCoinsDelivered = _purchaseService.onCoinsDelivered;
    _originalOnError = _purchaseService.onError;
    _originalOnStateChanged = _purchaseService.onStateChanged;

    // Setup shop-specific purchase callbacks
    _purchaseService.onCoinsDelivered = (coins) {
      setState(() => _displayCoins += coins);
      _showSuccessSnackbar(coins);
      // Call original so game_screen stays in sync
      _originalOnCoinsDelivered?.call(coins);
    };

    _purchaseService.onError = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    };

    _purchaseService.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    // Restore original callbacks so game_screen works after shop closes
    _purchaseService.onCoinsDelivered = _originalOnCoinsDelivered;
    _purchaseService.onError = _originalOnError;
    _purchaseService.onStateChanged = _originalOnStateChanged;
    super.dispose();
  }

  void _showSuccessSnackbar(int coins) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🪙', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              '+$coins coins added!',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    ...CoinPack.packs.asMap().entries.map(
                          (entry) => _buildPackCard(
                            entry.value,
                            entry.key,
                          ),
                        ),
                    const SizedBox(height: 16),
                    _buildRestoreButton(),
                    const SizedBox(height: 12),
                    _buildDisclaimer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
                iconSize: 26,
              ),
              const Expanded(
                child: Text(
                  'COIN SHOP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 12),
          // Coin balance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.15),
                  Colors.orange.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(
                  '$_displayCoins',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'COINS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(CoinPack pack, int index) {
    final colors = [
      [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
      [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
      [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
      [const Color(0xFFBF360C), const Color(0xFFE65100)],
      [const Color(0xFF00695C), const Color(0xFF00897B)],
      [const Color(0xFF283593), const Color(0xFF3949AB)],
    ];

    final cardColors = colors[index % colors.length];
    final isBestValue = pack.bonusLabel != null && pack.bonusLabel!.contains('BEST VALUE');
    final storePrice = _purchaseService.getPrice(pack.productId);
    final displayPrice = storePrice ?? pack.label;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: isBestValue
            ? Border.all(color: Colors.amber, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: cardColors[0].withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _purchaseService.isPurchasing
              ? null
              : () => _purchaseService.buyCoins(pack),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Coin icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text('🪙', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),

                // Coin info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${pack.coins}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            ' Coins',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (pack.bonusLabel != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isBestValue
                                ? Colors.amber
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pack.bonusLabel!,
                            style: TextStyle(
                              color: isBestValue
                                  ? Colors.black87
                                  : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Price button
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _purchaseService.isPurchasing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          displayPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton.icon(
      onPressed: () async {
        await _purchaseService.restorePurchases();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Purchases restored'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      icon: const Icon(Icons.restore_rounded, size: 18),
      label: const Text('Restore Purchases'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white38,
      ),
    );
  }

  Widget _buildDisclaimer() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Purchases are processed by Google Play. '
        'Coins are added instantly after successful payment. '
        'All sales are final.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white24,
          fontSize: 11,
          height: 1.4,
        ),
      ),
    );
  }
}
