import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/booking_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  late Future<List<Booking>> _myBookingsFuture;

  @override
  void initState() {
    super.initState();
    _myBookingsFuture = _fetchMyBookings();
  }

  Future<List<Booking>> _fetchMyBookings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw 'User not found';

      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((b) => Booking.fromJson(b)).toList();
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
      appBar: AppBar(title: const Text('My Bookings'), backgroundColor: Colors.blueAccent),
      body: FutureBuilder<List<Booking>>(
        future: _myBookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('You have no bookings yet.', style: TextStyle(fontSize: 18)));

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
                  subtitle: Text('Status: ${booking.bookingStatus}\nPayment: ${booking.paymentStatus}\nLocation: ${booking.pickupLocation}'),
                  trailing: Text('₹${booking.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.green)),
                  onTap: () => _showExtendBookingDialog(context, booking),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showExtendBookingDialog(BuildContext context, Booking booking) async {
    final hoursController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Booking'),
        content: TextField(
          controller: hoursController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Enter extra hours'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final extraHours = int.tryParse(hoursController.text.trim()) ?? 0;
              if (extraHours <= 0) return;
              final extraAmount = extraHours * 100.0; // Example ₹100/hr

              Navigator.pop(context);
              _startRazorpayPayment(booking, extraHours, extraAmount);
            },
            child: const Text('Pay & Extend'),
          ),
        ],
      ),
    );
  }

  void _startRazorpayPayment(Booking booking, int extraHours, double extraAmount) {
    final razorpay = Razorpay();
    var options = {
      'key': 'rzp_test_XXXXXXXXXXXX', // replace with your Razorpay key
      'amount': (extraAmount * 100).toInt(),
      'name': 'WheelShare',
      'description': 'Extra hours booking',
      'prefill': {'contact': '9999999999', 'email': 'user@example.com'},
      'currency': 'INR',
    };

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (res) async {
      await Supabase.instance.client
          .from('bookings')
          .update({
            'total_hours': booking.totalHours + extraHours,
            'total_amount': booking.totalAmount + extraAmount,
            'payment_status': 'Paid',
          })
          .eq('id', booking.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking extended successfully!'), backgroundColor: Colors.green),
      );

      setState(() {
        _myBookingsFuture = _fetchMyBookings();
      });
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed'), backgroundColor: Colors.red),
      );
    });

    razorpay.open(options);
  }
}
