// lib/booking_details_page.dart

import 'package:flutter/material.dart';
import 'package:wheelshare/booking_model.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingDetailsPage extends StatefulWidget {
  final Booking booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  late String _paymentStatus;
  bool _isHandoverConfirmed = false;
  late String _bookingStatus;

  @override
  void initState() {
    super.initState();
    _paymentStatus = widget.booking.paymentStatus;
    _bookingStatus = 'Ongoing'; // Initial booking status
  }

  void _updatePaymentStatus() {
    setState(() {
      _paymentStatus = 'Paid';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment status updated to Paid.')),
    );
  }

  void _confirmHandover() {
    setState(() {
      _isHandoverConfirmed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle handover confirmed.')),
    );
  }

  void _completeBooking() async {
    setState(() {
      _bookingStatus = 'Completed';
    });
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'booking_status': 'Completed'})
          .eq('booking_id', widget.booking.bookingId ?? '');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking marked as Completed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete booking: $e')),
      );
    }
  }

  void _takePhoto(String documentType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Camera opened to take a photo of $documentType.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User and Booking Information
            _buildSectionHeader('User & Booking Info'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Booking ID:', widget.booking.bookingId.toString()),
                    _buildDetailRow('User Name:', widget.booking.userName),
                    _buildDetailRow('Vehicle:', '${widget.booking.vehicleName} (${widget.booking.vehicleType})'),
                    _buildDetailRow('Location:', widget.booking.pickupLocation),
                    _buildDetailRow(
                      'Dates:',
                      '${DateFormat('dd/MM/yyyy').format(widget.booking.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.booking.endDate)}',
                    ),
                    _buildDetailRow('Duration:', '${widget.booking.totalHours} hours'),
                    const Divider(),
                    _buildDetailRow('Booking Status:', _bookingStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Section
            _buildSectionHeader('Payment Status'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Total Amount:', '₹${widget.booking.totalAmount.toStringAsFixed(2)}'),
                    _buildPaymentStatusRow(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Handover Section
            _buildSectionHeader('Vehicle Handover'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Photo with Vehicle'),
                      trailing: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _isHandoverConfirmed ? null : () => _takePhoto('User with Vehicle'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.credit_card),
                      title: const Text('Aadhaar / ID Card'),
                      trailing: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _isHandoverConfirmed ? null : () => _takePhoto('Aadhaar / ID Card'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.drive_eta),
                      title: const Text('Driver\'s License'),
                      trailing: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _isHandoverConfirmed ? null : () => _takePhoto('Driver\'s License'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isHandoverConfirmed ? null : _confirmHandover,
                        child: Text(_isHandoverConfirmed ? 'Handover Confirmed' : 'Confirm Handover'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Final Booking Status Section
            _buildSectionHeader('Finalize Booking'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _bookingStatus == 'Completed'
                          ? 'Booking has been finalized.'
                          : 'Mark the booking as completed after the vehicle is returned.',
                      style: TextStyle(
                        fontSize: 16,
                        color: _bookingStatus == 'Completed' ? Colors.green : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isHandoverConfirmed && _bookingStatus != 'Completed')
                            ? _completeBooking
                            : null,
                        child: const Text('Complete Booking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusRow() {
    Color statusColor = _paymentStatus == 'Paid' ? Colors.green : Colors.orange;
    String statusText = _paymentStatus == 'Paid' ? 'Paid' : 'Pending';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
              if (_paymentStatus == 'Pending')
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _updatePaymentStatus,
                  child: const Text('Mark as Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 30),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}