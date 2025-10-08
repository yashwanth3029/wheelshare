// lib/admin_home_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/booking_details_page.dart';
import 'package:wheelshare/booking_model.dart';
import 'package:wheelshare/add_vehicle_page.dart';
import 'package:wheelshare/view_vehicles_page.dart';
import 'package:wheelshare/login_page.dart'; // Import the single login page

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // We now fetch bookings from Supabase instead of using mock data.
  late final Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch the bookings when the widget is first created
    _bookingsFuture = _fetchBookings();
  }

  /// Fetches the list of bookings from the Supabase 'bookings' table.
  Future<List<Booking>> _fetchBookings() async {
    try {
      // Fetch data and order by the 'created_at' timestamp to show newest bookings first.
      // Supabase automatically adds a 'created_at' column to your tables.
      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      // Convert the raw list of maps into a list of Booking objects using the fromJson factory
      final bookings = (response as List)
          .map((bookingData) => Booking.fromJson(bookingData))
          .toList();
      return bookings;
    } catch (e) {
      // If an error occurs, we rethrow it to be caught by the FutureBuilder.
      // This allows us to display an error message in the UI.
      throw Exception('Failed to load bookings: $e');
    }
  }

  /// Signs the user out and navigates back to the login page.
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add New Vehicle'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddVehiclePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.car_rental),
              title: const Text('Manage Vehicles'),
              onTap: () {
                Navigator.of(context).pop(); // Close the drawer
                Navigator.of(context).push(
                  // CORRECTED: Was ViewVehiclePage (singular)
                  MaterialPageRoute(builder: (context) => const ViewVehiclesPage()),
                );
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.blueAccent),
                title: const Text('Add New Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AddVehiclePage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.car_rental, color: Colors.blueAccent),
                title: const Text('Manage Existing Vehicles', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ViewVehiclesPage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Bookings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 20),
            // Use a FutureBuilder to handle the loading, error, and data states.
            Expanded(
              child: FutureBuilder<List<Booking>>(
                future: _bookingsFuture,
                builder: (context, snapshot) {
                  // Show a loading spinner while waiting for data
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Show an error message if something went wrong
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  // Show a message if there are no bookings
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No bookings found.'));
                  }
                  
                  // If data is available, display it in a list
                  final bookings = snapshot.data!;
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
                                : Colors.orange, // For 'Pending' status
                            child: Text(
                              
                              booking.id.toString(), 
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('${booking.vehicleName} (${booking.vehicleType})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'User: ${booking.userName}\nStatus: ${booking.paymentStatus}\nTotal: ₹${booking.totalAmount.toStringAsFixed(2)}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          isThreeLine: true,
                          onTap: () {
                            // You can navigate to a details page here if needed
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BookingDetailsPage(booking: booking),
                              ),
                            );
                          },
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