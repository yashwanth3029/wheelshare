// lib/booking_model.dart

class Booking {
  final int id; // Assuming Supabase generates an auto-incrementing id
  final String userId;
  final String userName; // We might need to fetch this separately later
  final String vehicleName;
  final String vehicleType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalHours;
  final String pickupLocation;
  final double totalAmount;
  final String paymentStatus;
  final String depositDocument;

  Booking({
    required this.id,
    required this.userId,
    this.userName = 'N/A', // Default or fetch from a 'profiles' table
    required this.vehicleName,
    required this.vehicleType,
    required this.startDate,
    required this.endDate,
    required this.totalHours,
    required this.pickupLocation,
    required this.totalAmount,
    required this.paymentStatus,
    required this.depositDocument,
  });

  // Factory constructor to create a Booking from a Supabase record (JSON map)
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      // You might need to join with a profiles table to get user_name
      // For now, let's assume you might store it or default it.
      userName: json['user_name'] ?? 'Guest User', 
      vehicleName: json['vehicle_name'],
      vehicleType: json['vehicle_type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      totalHours: json['total_hours'],
      pickupLocation: json['pickup_location'],
      totalAmount: (json['total_price'] as num).toDouble(),
      paymentStatus: json['payment_status'],
      depositDocument: json['deposit_document'],
    );
  }

  Object? get bookingId => null;
}