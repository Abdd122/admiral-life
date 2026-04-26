
import 'package:cloud_firestore/cloud_firestore.dart';

class CoinPackage {
  final String id;
  final String name;
  final int coinsAmount;
  final double priceUSD;

  CoinPackage({
    required this.id,
    required this.name,
    required this.coinsAmount,
    required this.priceUSD,
  });

  factory CoinPackage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CoinPackage(
      id: doc.id,
      name: data['name'] ?? '',
      coinsAmount: data['coinsAmount'] ?? 0,
      priceUSD: (data['priceUSD'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coinsAmount': coinsAmount,
      'priceUSD': priceUSD,
    };
  }
}
