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

class BookingModel {
  final int? id;
  final int itemId;
  final int renterId;
  final String startDate;
  final String endDate;
  final int days;
  final double rentalFee;
  final double serviceFee;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? transactionId;
  final String bookingStatus; // 'active', 'completed', 'cancelled'
  final String createdAt;

  BookingModel({
    this.id,
    required this.itemId,
    required this.renterId,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.rentalFee,
    required this.serviceFee,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.transactionId,
    this.bookingStatus = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'item_id': itemId,
        'renter_id': renterId,
        'start_date': startDate,
        'end_date': endDate,
        'days': days,
        'rental_fee': rentalFee,
        'service_fee': serviceFee,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'transaction_id': transactionId,
        'booking_status': bookingStatus,
        'created_at': createdAt,
      };

  factory BookingModel.fromMap(Map<String, dynamic> map) => BookingModel(
        id: map['id'],
        itemId: map['item_id'],
        renterId: map['renter_id'],
        startDate: map['start_date'],
        endDate: map['end_date'],
        days: map['days'],
        rentalFee: (map['rental_fee'] as num).toDouble(),
        serviceFee: (map['service_fee'] as num).toDouble(),
        totalAmount: (map['total_amount'] as num).toDouble(),
        paymentMethod: map['payment_method'],
        paymentStatus: map['payment_status'] ?? 'pending',
        transactionId: map['transaction_id'],
        bookingStatus: map['booking_status'] ?? 'active',
        createdAt: map['created_at'],
      );
}

class ConversationModel {
  final int? id;
  final int itemId;
  final int ownerId;
  final int renterId;
  final String? lastMessage;
  final String? lastMessageAt;
  final String createdAt;

  // Populated via JOIN queries
  final String? itemTitle;
  final String? otherUserName;

  ConversationModel({
    this.id,
    required this.itemId,
    required this.ownerId,
    required this.renterId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.itemTitle,
    this.otherUserName,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) =>
      ConversationModel(
        id: map['id'] as int?,
        itemId: map['item_id'] as int,
        ownerId: map['owner_id'] as int,
        renterId: map['renter_id'] as int,
        lastMessage: map['last_message'] as String?,
        lastMessageAt: map['last_message_at'] as String?,
        createdAt: map['created_at'] as String,
        itemTitle: map['item_title'] as String?,
        otherUserName: map['other_user_name'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'item_id': itemId,
    'owner_id': ownerId,
    'renter_id': renterId,
    'last_message': lastMessage,
    'last_message_at': lastMessageAt,
    'created_at': createdAt,
  };
}

class MessageModel {
  final int? id;
  final int conversationId;
  final int senderId;
  final String content;
  final String createdAt;
  final bool isRead;

  MessageModel({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
    id: map['id'] as int?,
    conversationId: map['conversation_id'] as int,
    senderId: map['sender_id'] as int,
    content: map['content'] as String,
    createdAt: map['created_at'] as String,
    isRead: (map['is_read'] as int? ?? 0) == 1,
  );

  Map<String, dynamic> toMap() => {
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'created_at': createdAt,
    'is_read': isRead ? 1 : 0,
  };
}
