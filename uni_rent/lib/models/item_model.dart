class ItemModel {
  final int? id;
  final int ownerId;
  final String title;
  final String category;
  final String description;
  final double pricePerDay;
  final String location;
  final String? imagePath;
  final int isAvailable;
  final String createdAt;

  ItemModel({
    this.id,
    required this.ownerId,
    required this.title,
    required this.category,
    required this.description,
    required this.pricePerDay,
    required this.location,
    this.imagePath,
    this.isAvailable = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'owner_id': ownerId,
        'title': title,
        'category': category,
        'description': description,
        'price_per_day': pricePerDay,
        'location': location,
        'image_path': imagePath,
        'is_available': isAvailable,
        'created_at': createdAt,
      };

  factory ItemModel.fromMap(Map<String, dynamic> map) => ItemModel(
        id: map['id'],
        ownerId: map['owner_id'],
        title: map['title'],
        category: map['category'],
        description: map['description'],
        pricePerDay: (map['price_per_day'] as num).toDouble(),
        location: map['location'],
        imagePath: map['image_path'],
        isAvailable: map['is_available'] ?? 1,
        createdAt: map['created_at'],
      );

  bool get available => isAvailable == 1;
}
