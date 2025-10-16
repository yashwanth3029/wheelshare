import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wheelshare/edit_vehicle_page.dart';
import 'package:wheelshare/vehicle_models.dart';

class ViewVehiclesPage extends StatefulWidget {
  const ViewVehiclesPage({super.key});

  @override
  State<ViewVehiclesPage> createState() => _ViewVehiclesPageState();
}

class _ViewVehiclesPageState extends State<ViewVehiclesPage> {
  late Future<List<dynamic>> _allVehiclesFuture;

  @override
  void initState() {
    super.initState();
    _allVehiclesFuture = _fetchAllVehicles();
  }

  Future<List<dynamic>> _fetchAllVehicles() async {
    try {
      final carsFuture = Supabase.instance.client.from('cars').select();
      final bikesFuture = Supabase.instance.client.from('bikes').select();

      final responses = await Future.wait([carsFuture, bikesFuture]);

      final carsData = responses[0] as List;
      final bikesData = responses[1] as List;

      final List<dynamic> allVehicles = [];

      allVehicles.addAll(carsData.map((car) => Car.fromJson(car)));

      allVehicles.addAll(bikesData.map((bike) => Bike.fromJson(bike)));
      
      return allVehicles;
    } catch (e) {
      throw Exception('Failed to load vehicles: $e');
    }
  }

  Future<void> _deleteVehicle(dynamic vehicle, String type) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${vehicle.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        final tableName = '${type.toLowerCase()}s';
        await Supabase.instance.client
            .from(tableName)
            .delete()
            .match({'id': vehicle.id});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${vehicle.name} deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _allVehiclesFuture = _fetchAllVehicles();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete vehicle: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicles'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _allVehiclesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No vehicles found.'));
          }

          final vehicles = snapshot.data!;

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              String type;

              if (vehicle is Car) {
                type = 'Car';
              } else if (vehicle is Bike) {
                type = 'Bike';
              } else {
                return const SizedBox.shrink(); 
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      vehicle.image_url,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(vehicle.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Type: $type | Price: ₹${vehicle.price.toStringAsFixed(0)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditVehiclePage(vehicle: vehicle,),
                            ),
                          ).then((didUpdate) {
                            if (didUpdate == true) {
                              setState(() {
                                _allVehiclesFuture = _fetchAllVehicles();
                              });
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteVehicle(vehicle, type),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}