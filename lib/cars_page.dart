// lib/cars_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/vehicle_models.dart';
import 'package:wheelshare/booking_page.dart';

class CarsPage extends StatefulWidget {
  const CarsPage({super.key});

  @override
  State<CarsPage> createState() => _CarsPageState();
}

class _CarsPageState extends State<CarsPage> {
  late Future<List<Car>> _carsFuture; // Changed to match FutureBuilder's logic
  String _sortOrder = 'asc';
  final TextEditingController _searchController = TextEditingController();
  List<Car> _allCars = [];
  List<Car> _filteredCars = [];

  @override
  void initState() {
    super.initState();
    _carsFuture = _fetchCars();
    _searchController.addListener(_sortAndFilterCars);
  }

  // Updated to return the Future, which is then handled by the FutureBuilder
  Future<List<Car>> _fetchCars() async {
    try {
      final response = await Supabase.instance.client.from('cars').select();
      List<dynamic> data = response;
      _allCars = data.map((json) => Car.fromJson(json)).toList();
      _sortAndFilterCars();
      return _filteredCars;
    } catch (e) {
      // Return an empty list on failure to avoid the state setter error
      _filteredCars = [];
      throw Exception('Failed to load cars: $e');
    }
  }

  void _sortAndFilterCars() {
    // 1. Filter by search query
    _filteredCars = _allCars.where((car) {
      final nameLower = car.name.toLowerCase();
      final searchLower = _searchController.text.toLowerCase();
      return nameLower.contains(searchLower);
    }).toList();

    // 2. Sort by price
    if (_sortOrder == 'asc') {
      _filteredCars.sort((a, b) => a.price.compareTo(b.price));
    } else {
      _filteredCars.sort((a, b) => b.price.compareTo(a.price));
    }

    // Trigger UI rebuild
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_sortAndFilterCars);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cars for Rent'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // ----------------- New Search Bar in Body -----------------
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by car name...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // ----------------- Sorting Controls -----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sort by Price:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    // Low to High
                    Radio<String>(
                      value: 'asc',
                      groupValue: _sortOrder,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortOrder = value;
                            _sortAndFilterCars();
                          });
                        }
                      },
                    ),
                    const Text('Low'),
                    const SizedBox(width: 16),
                    // High to Low
                    Radio<String>(
                      value: 'desc',
                      groupValue: _sortOrder,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortOrder = value;
                            _sortAndFilterCars();
                          });
                        }
                      },
                    ),
                    const Text('High'),
                  ],
                ),
              ],
            ),
          ),
          // ----------------- Vehicle Grid (FutureBuilder) -----------------
          Expanded(
            child: FutureBuilder(
              future: _carsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (_allCars.isNotEmpty) {
                  // Display filtered list immediately
                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _filteredCars.length,
                    itemBuilder: (context, index) {
                      final car = _filteredCars[index];
                      return VehicleCard(vehicle: car, vehicleType: 'Car');
                    },
                  );
                } else {
                  return const Center(child: Text('No cars available.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// VehicleCard remains the same (defined here for completeness)
class VehicleCard extends StatelessWidget {
  final dynamic vehicle;
  final String vehicleType;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingPage(vehicle: vehicle, vehicleType: vehicleType),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  vehicle.image_url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${vehicle.price} / 12 hrs',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BookingPage(vehicle: vehicle, vehicleType: vehicleType),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}