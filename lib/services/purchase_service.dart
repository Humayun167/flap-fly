// lib/services/purchase_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/coin_pack.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  // Callback when coins are delivered
  void Function(int coins)? onCoinsDelivered;

  // Callback for error messages
  void Function(String message)? onError;

  // Callback for purchase state changes
  void Function()? onStateChanged;

  /// Initialize the purchase service and load products
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('PurchaseService: Store not available');
      return;
    }

    // Listen for purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('PurchaseService: Stream error: $error');
      },
    );

    // Load product details from store
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final productIds =
        CoinPack.packs.map((p) => p.productId).toSet();

    final response = await _iap.queryProductDetails(productIds);

    if (response.error != null) {
      debugPrint(
          'PurchaseService: Query error: ${response.error!.message}');
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
          'PurchaseService: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('PurchaseService: Loaded ${_products.length} products');
  }

  /// Get the store price for a product (returns null if not loaded)
  String? getPrice(String productId) {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      return product.price;
    } catch (_) {
      return null;
    }
  }

  /// Buy a coin pack
  Future<void> buyCoins(CoinPack pack) async {
    if (_isPurchasing) return;

    // Find the product details from the store
    ProductDetails? product;
    try {
      product = _products.firstWhere((p) => p.id == pack.productId);
    } catch (_) {
      // Product not found in store — fallback for testing
      onError?.call('Product not available. Make sure in-app products '
          'are configured in Google Play Console.');
      return;
    }

    _isPurchasing = true;
    onStateChanged?.call();

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // Consumable purchase (coins can be bought multiple times)
      await _iap.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );
    } catch (e) {
      _isPurchasing = false;
      onStateChanged?.call();
      onError?.call('Purchase failed. Please try again.');
      debugPrint('PurchaseService: Buy error: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseList) {
    for (final purchase in purchaseList) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _deliverCoins(purchase);
          break;
        case PurchaseStatus.error:
          _isPurchasing = false;
          onStateChanged?.call();
          onError?.call('Purchase failed: ${purchase.error?.message ?? 'Unknown error'}');
          break;
        case PurchaseStatus.canceled:
          _isPurchasing = false;
          onStateChanged?.call();
          break;
        case PurchaseStatus.pending:
          // Purchase pending — waiting for user to complete
          break;
      }

      // Complete pending purchases
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void _deliverCoins(PurchaseDetails purchase) {
    _isPurchasing = false;

    // Find the matching coin pack
    final pack = CoinPack.packs.where(
      (p) => p.productId == purchase.productID,
    );

    if (pack.isNotEmpty) {
      final coins = pack.first.coins;
      onCoinsDelivered?.call(coins);
      debugPrint('PurchaseService: Delivered $coins coins');
    }

    onStateChanged?.call();
  }

  /// Restore previous purchases (for Play Store compliance)
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
  }
}
