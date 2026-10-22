import 'customer_api.dart';
export '../demo/vehicle_demo.dart';
import '../models/vehicle.dart';

abstract interface class VehicleService {
  Future<List<Vehicle>> getVehicles(int customerId);

  Future<Vehicle> addVehicle(int customerId, VehicleInput input);
}


class ApiVehicleService implements VehicleService {
  ApiVehicleService(this.api);
  final CustomerApi api;
  Vehicle _parse(Map<String, dynamic> value) => Vehicle(id: value['id'] as int, customerId: value['customerId'] as int, plate: value['licensePlate'] as String, brand: value['brand'] as String? ?? '', model: value['model'] as String? ?? '', year: value['year'] as int?, mileage: value['mileage'] as int?);
  @override
  Future<List<Vehicle>> getVehicles(int customerId) async => (await api.request('/customers/$customerId/vehicles') as List).map((v) => _parse(v as Map<String, dynamic>)).toList();
  @override
  Future<Vehicle> addVehicle(int customerId, VehicleInput input) async => _parse(await api.request('/vehicles', method: 'POST', body: {'customerId': customerId, 'licensePlate': input.plate, 'brand': input.brand, 'model': input.model, 'year': input.year, 'mileage': input.mileage}) as Map<String, dynamic>);
}
