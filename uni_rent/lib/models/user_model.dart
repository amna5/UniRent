class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String university;
  final String role; // 'user' or 'admin'
  final double rating;
  final int reviewCount;
  final int itemsListed;
  final int rentalCount;
  final String memberSince;
  final int isActive;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.university,
    this.role = 'user',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.itemsListed = 0,
    this.rentalCount = 0,
    required this.memberSince,
    this.isActive = 1,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'password': password,
        'university': university,
        'role': role,
        'rating': rating,
        'review_count': reviewCount,
        'items_listed': itemsListed,
        'rental_count': rentalCount,
        'member_since': memberSince,
        'is_active': isActive,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        password: map['password'],
        university: map['university'],
        role: map['role'] ?? 'user',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: map['review_count'] ?? 0,
        itemsListed: map['items_listed'] ?? 0,
        rentalCount: map['rental_count'] ?? 0,
        memberSince: map['member_since'] ?? '',
        isActive: map['is_active'] ?? 1,
      );

  bool get isAdmin => role == 'admin';
}
