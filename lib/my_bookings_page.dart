// lib/my_bookings_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/booking_model.dart'; // Make sure to import your model

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  late final Future<List<Booking>> _myBookingsFuture;

  @override
  void initState() {
    super.initState();
    _myBookingsFuture = _fetchMyBookings();
  }

  Future<List<Booking>> _fetchMyBookings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw 'User not found.';
      }

      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('user_id', user.id) // Key difference: filter by user_id
          .order('created_at', ascending: false);
      
      final bookings = (response as List)
          .map((data) => Booking.fromJson(data))
          .toList();
      return bookings;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to fetch bookings: $e'),
        backgroundColor: Colors.red,
      ));
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Booking>>(
        future: _myBookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no bookings yet.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(booking.vehicleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Status: ${booking.paymentStatus}\nLocation: ${booking.pickupLocation}'),
                  trailing: Text('₹${booking.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, color: Colors.green)),
                  onTap: () {
                    // Optional: Navigate to a detailed view of this booking
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}