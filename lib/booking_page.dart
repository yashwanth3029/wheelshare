
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/home_page.dart';
import 'package:wheelshare/admin_home_page.dart';
import 'package:wheelshare/vehicle_models.dart';

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
  static const String _razorpayKeyId = 'rzp_test_RSrHHLj5py8Lll';
  
  late Razorpay _razorpay;
  
  final _formKey = GlobalKey<FormState>();
  
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
  
  String _paymentOption = 'pay_on_location';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _calculatePrice() {
    if (_startDate != null && _endDate != null && _startTime != null && _endTime != null) {
      final startDateTime = DateTime(
        _startDate!.year, _startDate!.month, _startDate!.day,
        _startTime!.hour, _startTime!.minute,
      );
      final endDateTime = DateTime(
        _endDate!.year, _endDate!.month, _endDate!.day,
        _endTime!.hour, _endTime!.minute,
      );

      final duration = endDateTime.difference(startDateTime);
      _totalHours = duration.inHours;

      double subtotal = (widget.vehicle.price.toDouble() + (_totalHours > 12 ? (_totalHours - 12) * _hourlyRate : 0.0));
      double gst = subtotal * _gstRate;
      double total = subtotal + gst + _platformFee + _securityDeposit;
      _totalPrice = total;
    } else {
      _totalHours = 0;
      _totalPrice = 0.0;
    }
  }

  Future<void> _saveBooking(String paymentStatus) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a booking.')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('bookings').insert({
        'user_id': user.id,
        'username': (await Supabase.instance.client.from('users').select('username').eq('id', user.id).single())['username'],
        'vehicle_id': widget.vehicle.id,
        'vehicle_name': widget.vehicle.name,
        'vehicle_type': widget.vehicleType,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'total_hours': _totalHours,
        'pickup_location': _selectedLocation,
        'deposit_document': _selectedDeposit,
        'total_amount': _totalPrice,
        'payment_status': paymentStatus,
        'booking_status': 'pending',
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking created successfully!')),
      );

      final isAdmin = (await Supabase.instance.client.from('users').select('is_admin').eq('id', user.id).single())['is_admin'] as bool;
      if (isAdmin) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminHomePage()),
          (Route<dynamic> route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      }

    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving booking: ${e.message}')),
      );
    }
  }
  
  void _openRazorpayCheckout() {
    var options = {
      'key': _razorpayKeyId,
      'amount': (_totalPrice * 100).toInt(),
      'name': 'WheelShare Booking',
      'description': 'Booking for ${widget.vehicle.name}',
      'prefill': {
        'contact': '9876543210',
        'email': 'customer@example.com'
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful: ${response.paymentId}')),
    );
    _saveBooking('Paid');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
    _saveBooking('Failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  void _handleBooking() {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocation == null || _selectedDeposit == null || _totalHours < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select all booking details. Minimum booking time is 12 hours.')),
        );
        return;
      }
      
      if (_paymentOption == 'pay_now') {
        _openRazorpayCheckout();
      } else {
        _saveBooking('To Be Paid');
      }
    }
  }
  
  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _endDate = null;
        } else {
          _endDate = picked;
        }
        _calculatePrice();
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _calculatePrice();
      });
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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      child: Text(_startDate == null ? 'Select Start Date' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectTime(true),
                      child: Text(_startTime == null ? 'Select Start Time' : _startTime!.format(context)),
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
                      child: Text(_endDate == null ? 'Select End Date' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _selectTime(false),
                      child: Text(_endTime == null ? 'Select End Time' : _endTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
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
                          Text('${_totalHours} hours'),
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
                            Text('₹${((_totalHours - 12) * _hourlyRate).toStringAsFixed(2)}'),
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
                          Text('₹${((widget.vehicle.price + (_totalHours > 12 ? (_totalHours - 12) * _hourlyRate : 0.0)) * _gstRate).toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('₹${((widget.vehicle.price + (_totalHours > 12 ? (_totalHours - 12) * _hourlyRate : 0.0)) + ((widget.vehicle.price + (_totalHours > 12 ? (_totalHours - 12) * _hourlyRate : 0.0)) * _gstRate)).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Security Deposit'),
                          Text('₹${_securityDeposit.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text('Book Now', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}