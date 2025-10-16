import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/booking_details_page.dart';
import 'package:wheelshare/booking_model.dart';
import 'package:wheelshare/add_vehicle_page.dart';
import 'package:wheelshare/view_vehicles_page.dart';
import 'package:wheelshare/login_page.dart';
import 'dart:math' show pi;

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late Future<List<Booking>> _bookingsFuture;
  List<Booking> _bookings = [];
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _fetchBookings();
  }

  Future<List<Booking>> _fetchBookings() async {
    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      if (response is List) {
        final bookings =
            response.map((b) => Booking.fromJson(b)).toList(growable: false);
        _bookings = bookings;
        return bookings;
      } else {
        throw Exception('Unexpected response format from Supabase');
      }
    } catch (e) {
      throw Exception('Failed to load bookings: $e');
    }
  }

  Future<void> _markBookingCompleted(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'booking_status': 'done'})
          .eq('id', bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking marked as completed!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _bookingsFuture = _fetchBookings();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sortBookings(String criterion) {
    setState(() {
      _sortBy = criterion;
      switch (criterion) {
        case 'recent':
          _bookings.sort((a, b) => b.startDate.compareTo(a.startDate));
          break;
        case 'date':
          _bookings.sort((a, b) => a.startDate.compareTo(b.startDate));
          break;
        case 'month':
          _bookings.sort((a, b) =>
              a.startDate.month.compareTo(b.startDate.month));
          break;
        case 'year':
          _bookings.sort((a, b) =>
              a.startDate.year.compareTo(b.startDate.year));
          break;
      }
    });
  }

  void _openVerificationDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Verify User - ${booking.username}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, color: Colors.blue, size: 40),
              const SizedBox(height: 10),
              Text('Aadhaar: Verified ✅'),
              Text('License: Verified ✅'),
              Text('Deposit Document: ${booking.depositDocument.isNotEmpty ? "Uploaded ✅" : "Not Provided ❌"}'),
              const SizedBox(height: 10),
              Text('Payment Status: ${booking.paymentStatus}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.pop(context);
                _markBookingCompleted(booking.id.toString());
              },
              child: const Text('Mark as Completed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildAnimatedCard(
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.rotate(
            angle: (1 - value) * pi / 12,
            child: GestureDetector(
              onTap: onTap,
              child: Card(
                color: color.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 50, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.blueAccent),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text('Admin Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add New Vehicle'),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddVehiclePage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.car_rental),
              title: const Text('Manage Vehicles'),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ViewVehiclesPage()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Two animated boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildAnimatedCard(
                    title: "Add",
                    icon: Icons.add_circle,
                    color: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddVehiclePage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnimatedCard(
                    title: "Edit",
                    icon: Icons.directions_car,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ViewVehiclesPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Booking section header + sort dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bookings',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'recent', child: Text('Recent')),
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'month', child: Text('Month')),
                    DropdownMenuItem(value: 'year', child: Text('Year')),
                  ],
                  onChanged: (value) {
                    if (value != null) _sortBookings(value);
                  },
                ),
              ],
            ),
            const Divider(height: 20),

            // Bookings list
            Expanded(
              child: FutureBuilder<List<Booking>>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No bookings found.'));
                  }

                  final bookings = _bookings;
                  return ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: booking.paymentStatus == 'Paid'
                                ? Colors.green
                                : Colors.orange,
                            child: Text(
                              booking.id.toString(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '${booking.vehicleName} (${booking.vehicleType})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'User: ${booking.username}\nPayment: ${booking.paymentStatus}\nStatus: ${booking.bookingStatus}\nTotal: ₹${booking.totalAmount.toStringAsFixed(2)}',
                          ),
                          onTap: () => _openVerificationDialog(booking),
                          trailing: booking.bookingStatus != 'done'
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () =>
                                      _markBookingCompleted(booking.id.toString()),
                                  child: const Text('Complete'),
                                )
                              : const Icon(Icons.check_circle,
                                  color: Colors.green),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
