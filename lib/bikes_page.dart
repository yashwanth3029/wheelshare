
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/vehicle_models.dart';
import 'package:wheelshare/booking_page.dart';
import 'package:wheelshare/cars_page.dart'; 

class BikesPage extends StatefulWidget {
  const BikesPage({super.key});

  @override
  State<BikesPage> createState() => _BikesPageState();
}

class _BikesPageState extends State<BikesPage> {
  late Future<List<Bike>> _bikesFuture;
  String _sortOrder = 'asc';
  final TextEditingController _searchController = TextEditingController();
  List<Bike> _allBikes = [];
  List<Bike> _filteredBikes = [];

  @override
  void initState() {
    super.initState();
    _bikesFuture = _fetchBikes();
    _searchController.addListener(_sortAndFilterBikes);
  }

  Future<List<Bike>> _fetchBikes() async {
    try {
      final response = await Supabase.instance.client.from('bikes').select();
      List<dynamic> data = response;
      _allBikes = data.map((json) => Bike.fromJson(json)).toList();
      _sortAndFilterBikes();
      return _filteredBikes;
    } catch (e) {
      _filteredBikes = [];
      throw Exception('Failed to load bikes: $e');
    }
  }

  void _sortAndFilterBikes() {
    _filteredBikes = _allBikes.where((bike) {
      final nameLower = bike.name.toLowerCase();
      final searchLower = _searchController.text.toLowerCase();
      return nameLower.contains(searchLower);
    }).toList();

    if (_sortOrder == 'asc') {
      _filteredBikes.sort((a, b) => a.price.compareTo(b.price));
    } else {
      _filteredBikes.sort((a, b) => b.price.compareTo(a.price));
    }

    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_sortAndFilterBikes);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bikes for Rent'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
         
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by bike name...',
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
                   
                    Radio<String>(
                      value: 'asc',
                      groupValue: _sortOrder,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortOrder = value;
                            _sortAndFilterBikes();
                          });
                        }
                      },
                    ),
                    const Text('Low'),
                    const SizedBox(width: 16),
                    
                    Radio<String>(
                      value: 'desc',
                      groupValue: _sortOrder,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortOrder = value;
                            _sortAndFilterBikes();
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
          
          Expanded(
            child: FutureBuilder(
              future: _bikesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (_allBikes.isNotEmpty) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _filteredBikes.length,
                    itemBuilder: (context, index) {
                      final bike = _filteredBikes[index];
                      return VehicleCard(vehicle: bike, vehicleType: 'Bike');
                    },
                  );
                } else {
                  return const Center(child: Text('No bikes available.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}