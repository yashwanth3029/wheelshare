// lib/policy_page.dart

import 'package:flutter/material.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Policy'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WheelShare Rental Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '1. Eligibility and Documentation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'To rent a vehicle from WheelShare, you must be at least 18 years of age and hold a valid, original driver\'s license. This license, along with a valid ID proof (Aadhaar, Passport, etc.), must be presented at the time of pickup. Failure to provide these documents will result in cancellation of your booking without a refund.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '2. Booking and Payments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Bookings can be made through our app by selecting your desired vehicle, dates, and times. A minimum booking duration of 12 hours is required. You can choose to "Pay Now" via our secure payment gateway or "Pay on Location." A security deposit will be charged upon payment, which is refundable upon the safe return of the vehicle.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '3. Vehicle Use and Responsibility',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'The renter is responsible for the vehicle from the time of pickup until it is returned. The vehicle must be used in accordance with all local traffic laws. Any fines or penalties incurred during the rental period are the sole responsibility of the renter. Smoking and alcohol consumption are strictly prohibited inside the vehicles.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}