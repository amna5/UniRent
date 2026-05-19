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
  final String? stripePaymentIntentId;
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
    this.stripePaymentIntentId,
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
        'stripe_payment_intent_id': stripePaymentIntentId,
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
        stripePaymentIntentId: map['stripe_payment_intent_id'],
        bookingStatus: map['booking_status'] ?? 'active',
        createdAt: map['created_at'],
      );
}
