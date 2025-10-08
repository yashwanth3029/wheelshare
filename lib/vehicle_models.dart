// lib/vehicle_models.dart

class Car {
  final String id; // MODIFIED: Changed from int to String
  final String name;
  final String image_url;
  final String model;
  final double price; // MODIFIED: Changed to double for consistency

  Car({
    required this.id,
    required this.name,
    required this.image_url,
    required this.model,
    required this.price,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as String, // MODIFIED: Read ID directly as a String
      name: json['name'] as String,
      image_url: json['image_url'] ?? 'https://via.placeholder.com/200',
      model: json['model'] as String? ?? 'Unknown',
      price: (json['price'] as num).toDouble(), // MODIFIED: Parse price as double
    );
  }
}

class Bike {
  final String id; // MODIFIED: Changed from int to String
  final String name;
  final String image_url;
  final double price; // MODIFIED: Changed to double for consistency

  Bike({
    required this.id,
    required this.name,
    required this.image_url,
    required this.price,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] as String, // MODIFIED: Read ID directly as a String
      name: json['name'] as String,
      image_url: json['image_url'] ?? 'https://via.placeholder.com/200',
      price: (json['price'] as num).toDouble(), // MODIFIED: Parse price as double
    );
  }
}