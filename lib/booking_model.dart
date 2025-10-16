// lib/booking_model.dart

class Booking {
  final int id; // Auto-generated ID from Supabase
  final String userId;
  final String userName;

  final String vehicleName;
  final String vehicleType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalHours;
  final String pickupLocation;
  final double totalAmount;
  final String paymentStatus;
  final String depositDocument;

  // Used to track progress or completion
  final String bookingStatus;

  Booking({
    required this.id,
    required this.userId,
    this.userName = 'N/A',
    required this.vehicleName,
    required this.vehicleType,
    required this.startDate,
    required this.endDate,
    required this.totalHours,
    required this.pickupLocation,
    required this.totalAmount,
    required this.paymentStatus,
    required this.depositDocument,
    this.bookingStatus = 'pending',
  });

  /// ✅ Add backward-compatible getters for older references
  String get username => userName;

  /// ✅ Add getter for bookingId (resolves your new error)
  int get bookingId => id;

  /// Factory constructor to create a Booking object from Supabase JSON map
  factory Booking.fromJson(Map<String, dynamic> json) {
    // --- Helper functions for safe parsing ---
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    // --- Return a constructed Booking object ---
    return Booking(
      id: parseInt(json['id']),
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      userName: (json['user_name'] ??
              json['username'] ??
              json['userName'] ??
              'Guest User')
          .toString(),
      vehicleName: (json['vehicle_name'] ?? json['vehicleName'] ?? '').toString(),
      vehicleType: (json['vehicle_type'] ?? json['vehicleType'] ?? '').toString(),
      startDate: parseDate(json['start_date'] ?? json['startDate']),
      endDate: parseDate(json['end_date'] ?? json['endDate']),
      totalHours: parseInt(json['total_hours'] ?? json['totalHours']),
      pickupLocation:
          (json['pickup_location'] ?? json['pickupLocation'] ?? '').toString(),
      totalAmount:
          parseDouble(json['total_price'] ?? json['totalPrice'] ?? json['totalAmount']),
      paymentStatus:
          (json['payment_status'] ?? json['paymentStatus'] ?? 'unpaid').toString(),
      depositDocument:
          (json['deposit_document'] ?? json['depositDocument'] ?? '').toString(),
      bookingStatus:
          (json['booking_status'] ?? json['bookingStatus'] ?? 'pending').toString(),
    );
  }
}
