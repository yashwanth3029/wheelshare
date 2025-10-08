// lib/refund_page.dart

import 'package:flutter/material.dart';

class RefundPage extends StatelessWidget {
  const RefundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refund Policy'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancellation and Refund Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '1. Cancellation Window',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You can cancel your booking up to 24 hours before your scheduled pickup time for a full refund of the total booking amount (excluding the non-refundable platform fee). Cancellations made within 24 hours will be subject to a partial refund, as per our terms.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '2. Refund Process',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'All refunds are processed to your original payment method. The refund amount will be displayed in your app wallet once processed. You may then choose to withdraw the amount to your bank account or use it for a future booking. Refund processing times may vary depending on your bank.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '3. Refundable Security Deposit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'The security deposit will be fully refunded to your account after the vehicle is safely returned and inspected for damage. This process typically takes 3-5 business days.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}