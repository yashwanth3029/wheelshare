import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheelshare/cars_page.dart';
import 'package:wheelshare/bikes_page.dart';
import 'package:wheelshare/my_bookings_page.dart';
import 'package:wheelshare/policy_page.dart';
import 'package:wheelshare/refund_page.dart';
import 'package:wheelshare/login_page.dart';
import 'package:wheelshare/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = 'User Name';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'User Name';
    });
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to log out?'),
                SizedBox(height: 16),
                Text('Do you want to save your account for quick login next time?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Log Out & Don\'t Save'),
              onPressed: () async {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('saved_user_email');
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            ElevatedButton(
              child: const Text('Log Out & Save'),
              onPressed: () async {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await prefs.setString('saved_user_email', user.email!);
                }
                await Supabase.instance.client.auth.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black), 
        title: Row(
          children: [
            const Icon(Icons.directions_car, color: Colors.black),
            const SizedBox(width: 8),
            const Text(
              'WheelShare',
              style: TextStyle(
                color: Colors.black, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(_username, style: const TextStyle(color: Colors.black)), 
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                  _loadUsername();
                },
                child: const Icon(Icons.person, color: Colors.black), 
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Text(
                'WheelShare Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('My Bookings'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MyBookingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.policy),
              title: const Text('Policy'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PolicyPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Refund'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const RefundPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OpenContainer(
                transitionDuration: const Duration(milliseconds: 500),
                closedElevation: 6.0,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                closedColor: Colors.blue.shade100,
                transitionType: ContainerTransitionType.fadeThrough,
                openBuilder: (context, action) {
                  return const CarsPage();
                },
                closedBuilder: (context, action) {
                  return InkWell(
                    onTap: action,
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      height: 208,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car, size: 60, color: Colors.blue),
                          SizedBox(height: 16),
                          Text(
                            'Book Your Car Now',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '"The car is a member of your family."',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.blueGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              OpenContainer(
                transitionDuration: const Duration(milliseconds: 500),
                closedElevation: 6.0,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                closedColor: Colors.orange.shade100,
                transitionType: ContainerTransitionType.fadeThrough,
                openBuilder: (context, action) {
                  return const BikesPage();
                },
                closedBuilder: (context, action) {
                  return InkWell(
                    onTap: action,
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      height: 208,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.two_wheeler, size: 60, color: Colors.orange),
                          SizedBox(height: 16),
                          Text(
                            'Book Your Bike Now',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '"Life is like riding a bicycle. To keep your balance you must keep moving."',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.brown,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Why Choose Us?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'WheelShare offers a seamless and reliable way to rent cars and bikes. Our user-friendly app, simple booking process, and a wide variety of vehicles make us the top choice for your travel needs.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              // Footer
              Center(
                child: Text(
                  '© 2025 WheelShare. All rights reserved.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}