
class Gift {
  final String id;
  final String name;
  final int cost;
  final String imageUrl;
  final String type; // e.g., 'gif', 'svg', 'mp4'
  final String category; // e.g., 'Popular', 'Luxury', 'Fun'

  Gift({
    required this.id,
    required this.name,
    required this.cost,
    required this.imageUrl,
    this.type = 'gif', // Default to gif if not provided
    required this.category,
  });

  // Factory constructor to create a Gift from a Firestore document
  factory Gift.fromMap(Map<String, dynamic> data, String documentId) {
    return Gift(
      id: documentId,
      name: data['name'] ?? '',
      cost: data['cost'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? 'gif',
      category: data['category'] ?? 'General',
    );
  }
}
