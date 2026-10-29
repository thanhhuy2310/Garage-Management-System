import 'customer_api.dart';
export '../demo/home_demo.dart';
import '../models/customer_profile.dart';
import '../models/home_summary.dart';

abstract interface class HomeService {
  Future<CustomerProfile> getProfile(int customerId);

  Future<HomeSummary> getSummary(int customerId);
}

class ApiHomeService implements HomeService {
  ApiHomeService(this.api);
  final CustomerApi api;
  @override
  Future<CustomerProfile> getProfile(int customerId) async {
    final data = await api.request('/customer/profile') as Map<String, dynamic>;
    return CustomerProfile(
      id: data['id'] as int,
      fullName: data['fullName'] as String,
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
    );
  }

  @override
  Future<HomeSummary> getSummary(int customerId) async {
    final values = await Future.wait([
      api.request('/customers/$customerId/vehicles'),
      api.request('/customer/repairs'),
      api.request('/appointments'),
    ]);
    final upcoming =
        (values[2] as List)
            .where(
              (a) =>
                  ['CHO_XAC_NHAN', 'DA_XAC_NHAN'].contains(a['status']) &&
                  DateTime.parse("${a['date']}T${a['time']}+07:00")
                      .isAfter(DateTime.now()),
            )
            .toList()
          ..sort(
            (a, b) => ("${a['date']} ${a['time']}").compareTo(
              "${b['date']} ${b['time']}",
            ),
          );
    return HomeSummary(
      vehicleCount: (values[0] as List).length,
      upcomingAppointment: upcoming.isEmpty
          ? null
          : "${upcoming.first['date']} · ${upcoming.first['time'].toString().substring(0, 5)}",
      activeRepairCount: (values[1] as List)
          .where(
            (r) =>
                !['HOAN_TAT', 'DA_HUY', 'HUY'].contains(r['order']['status']),
          )
          .length,
      pendingQuotationCount: 0,
      unreadNotificationCount: 0,
      hasConnectedCustomerExperience: false,
    );
  }
}
