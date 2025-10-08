// lib/booking_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW: Import Supabase
import 'package:intl/intl.dart';
import 'package:wheelshare/my_bookings_page.dart'; // NEW: Import the page to navigate to after booking

class BookingPage extends StatefulWidget {
  final dynamic vehicle;
  final String vehicleType;

  const BookingPage({
    super.key,
    required this.vehicle,
    required this.vehicleType,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  
  // NEW: State variable to handle loading indicator on the button
  bool _isLoading = false; 

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  int _totalHours = 0;
  double _totalPrice = 0.0;
  final double _hourlyRate = 100.0;
  final double _gstRate = 0.05;
  final double _platformFee = 50.0;
  final double _securityDeposit = 500.0;

  final List<String> _pickupLocations = [
    'Gachibowli',
    'Hitech City',
    'Kondapur',
    'Jubilee Hills',
  ];
  String? _selectedLocation;

  final List<String> _depositOptions = [
    'Aadhaar Card',
    'Passport',
    'Voter ID',
    'Original Driver\'s License',
  ];
  String? _selectedDeposit;

  String _paymentOption = 'pay_on_location'; // Default payment option

  void _calculatePrice() {
    if (_startDate != null &&
        _endDate != null &&
        _startTime != null &&
        _endTime != null) {
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      // Ensure end date is after start date
      if (endDateTime.isBefore(startDateTime)) {
         setState(() {
           _totalHours = 0;
           _totalPrice = 0.0;
         });
         return;
      }

      final duration = endDateTime.difference(startDateTime);
      _totalHours = duration.inHours;

      double subtotal =
          (widget.vehicle.price +
          (_totalHours > 12 ? (_totalHours - 12) * _hourlyRate : 0.0));
      double gst = subtotal * _gstRate;
      // Recalculate total price correctly
      _totalPrice = subtotal + gst + _platformFee + _securityDeposit;

      // Update the state to reflect the new price on the UI
      setState(() {});

    } else {
      setState(() {
        _totalHours = 0;
        _totalPrice = 0.0;
      });
    }
  }

  // NEW: Function to save the booking data to your Supabase table
  Future<void> _saveBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // This should ideally never happen if your app flow is correct
        throw 'User is not authenticated.';
      }

      final startDateTime = DateTime(
        _startDate!.year, _startDate!.month, _startDate!.day,
        _startTime!.hour, _startTime!.minute,
      );
      final endDateTime = DateTime(
        _endDate!.year, _endDate!.month, _endDate!.day,
        _endTime!.hour, _endTime!.minute,
      );

      final bookingData = {
        'user_id': user.id,
        'user_name': user.email, // It's better to get a name from a 'profiles' table if you have one
        'vehicle_id': widget.vehicle.id, // IMPORTANT: Make sure your vehicle object has an 'id'
        'vehicle_name': widget.vehicle.name, // And a 'name'
        'vehicle_type': widget.vehicleType,
        'start_date': startDateTime.toIso8601String(),
        'end_date': endDateTime.toIso8601String(),
        'total_hours': _totalHours,
        'pickup_location': _selectedLocation,
        'deposit_document': _selectedDeposit,
        'total_price': _totalPrice,
        'payment_status': 'Pending', // This is for 'Pay on Location'
      };

      // Insert data into the 'bookings' table
      await Supabase.instance.client.from('bookings').insert(bookingData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // After successful booking, take the user to their bookings list
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyBookingsPage()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // MODIFIED: This function now calls _saveBooking()
  void _handlePayment() {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null ||
          _selectedDeposit == null ||
          _totalHours < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select all booking details. Minimum booking time is 12 hours.',
            ),
          ),
        );
        return;
      }

      if (_paymentOption == 'pay_now') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Online payment will be implemented soon!')),
        );
      } else {
        // For 'pay_on_location', call the function to save data to Supabase
        _saveBooking();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Your ${widget.vehicleType}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vehicle Details
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.vehicle.image_url,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.vehicle.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Price: ₹${widget.vehicle.price} / 12 hrs',
                      style: const TextStyle(fontSize: 18, color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // New Date & Time Picker Section
              const Text(
                'Select Start and End Date & Time',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(true),
                      child: Text(
                        _startDate == null
                            ? 'Select Start Date'
                            : DateFormat('dd/MM/yyyy').format(_startDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectTime(true),
                      child: Text(
                        _startTime == null
                            ? 'Select Start Time'
                            : _startTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectDate(false),
                      child: Text(
                        _endDate == null
                            ? 'Select End Date'
                            : DateFormat('dd/MM/yyyy').format(_endDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectTime(false),
                      child: Text(
                        _endTime == null
                            ? 'Select End Time'
                            : _endTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pickup Location
              const Text(
                'Pickup Location',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Select a location',
                  border: OutlineInputBorder(),
                ),
                items: _pickupLocations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a pickup location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Important Notice Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Notice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'For a smooth pickup, you MUST bring your original driver\'s license and the deposit document you select below. Failure to do so will result in cancellation of your booking.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Deposit Options
              const Text(
                'Select a Deposit Document',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDeposit,
                decoration: const InputDecoration(
                  labelText: 'Select a document',
                  border: OutlineInputBorder(),
                ),
                items: _depositOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDeposit = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a deposit document';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Payment Summary
              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rental Duration'),
                          Text('$_totalHours hours'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Base Price (12 hrs)'),
                          Text('₹${widget.vehicle.price.toStringAsFixed(2)}'),
                        ],
                      ),
                      if (_totalHours > 12)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Additional Hours'),
                            Text(
                              '₹${((_totalHours - 12) * _hourlyRate).toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Platform Fee'),
                          Text('₹${_platformFee.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GST (5%)'),
                          Text(
                            '₹${((widget.vehicle.price + (_totalHours > 12 ? (_totalHours - 12) * _hourlyRate : 0.0)) * _gstRate).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text(
                            '₹${((widget.vehicle.price + (_totalHours > 12 ? (_totalHours - 12) * _hourlyRate : 0.0)) + ((widget.vehicle.price + (_totalHours > 12 ? (_totalHours - 12) * _hourlyRate : 0.0)) * _gstRate)).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Security Deposit'),
                          Text(
                            '₹${_securityDeposit.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Payable',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${_totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Payment Options
              const Text(
                'Choose a payment option',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Pay on Location'),
                value: 'pay_on_location',
                groupValue: _paymentOption,
                onChanged: (value) {
                  setState(() {
                    _paymentOption = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Pay Now (Card, UPI, Netbanking)'),
                value: 'pay_now',
                groupValue: _paymentOption,
                onChanged: (value) {
                  setState(() {
                    _paymentOption = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // MODIFIED Book Now Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // Disable the button when loading to prevent multiple clicks
                  onPressed: _isLoading ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      // Show a loading circle when processing
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      // Otherwise, show the text
                      : const Text(
                          'Book Now',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on _BookingPageState {
  Future<void> _selectDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      // Prevent selecting a date before today for start date
      // For end date, prevent selecting a date before the start date
      firstDate: isStart ? DateTime.now() : (_startDate ?? DateTime.now()),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if it's now before the new start date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
        _calculatePrice();
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _calculatePrice();
      });
    }
  }
}