

class Car {
  final String id;
  final String name;
  final String image_url;
  final String model;
  final double price;

  Car({
    required this.id,
    required this.name,
    required this.image_url,
    required this.model,
    required this.price,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as String,
      name: json['name'] as String,
      image_url: json['image_url'] ?? 'https://via.placeholder.com/200',
      model: json['model'] as String? ?? 'Unknown',
      price: (json['price'] as num).toDouble(),
    );
  }
}

class Bike {
  final String id;
  final String name;
  final String image_url;
  final double price;

  Bike({
    required this.id,
    required this.name,
    required this.image_url,
    required this.price,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] as String,
      name: json['name'] as String,
      image_url: json['image_url'] ?? 'https://via.placeholder.com/200',
      price: (json['price'] as num).toDouble(),
    );
  }
}
