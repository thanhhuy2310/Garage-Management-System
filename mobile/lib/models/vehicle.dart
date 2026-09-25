class Vehicle {
  const Vehicle({
    required this.id,
    required this.customerId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
  });

  final int id;
  final int customerId;
  final String plate;
  final String brand;
  final String model;
  final int? year;
  final int? mileage;
}

class VehicleInput {
  const VehicleInput({
    required this.plate,
    required this.brand,
    required this.model,
    this.year,
    this.mileage,
  });

  final String plate;
  final String brand;
  final String model;
  final int? year;
  final int? mileage;
}
