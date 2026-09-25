import '../models/vehicle.dart';

abstract interface class VehicleService {
  Future<List<Vehicle>> getVehicles(int customerId);

  Future<Vehicle> addVehicle(int customerId, VehicleInput input);
}

class MockVehicleService implements VehicleService {
  MockVehicleService();

  final List<Vehicle> _vehicles = [
    const Vehicle(
      id: 1,
      customerId: 1,
      plate: '51G-123.45',
      brand: 'Toyota',
      model: 'Camry',
      year: 2020,
      mileage: 45200,
    ),
    const Vehicle(
      id: 2,
      customerId: 1,
      plate: '51A-456.78',
      brand: 'Honda',
      model: 'CR-V',
      year: 2019,
      mileage: 62100,
    ),
  ];

  @override
  Future<List<Vehicle>> getVehicles(int customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return List.unmodifiable(
      _vehicles.where((vehicle) => vehicle.customerId == customerId),
    );
  }

  @override
  Future<Vehicle> addVehicle(int customerId, VehicleInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final vehicle = Vehicle(
      id:
          _vehicles.fold<int>(
            0,
            (maxId, item) => item.id > maxId ? item.id : maxId,
          ) +
          1,
      customerId: customerId,
      plate: input.plate.trim().toUpperCase(),
      brand: input.brand.trim(),
      model: input.model.trim(),
      year: input.year,
      mileage: input.mileage,
    );
    _vehicles.add(vehicle);
    return vehicle;
  }
}
