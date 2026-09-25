import '../models/customer_profile.dart';
import '../models/home_summary.dart';

abstract interface class HomeService {
  Future<CustomerProfile> getProfile(int customerId);

  Future<HomeSummary> getSummary(int customerId);
}

class MockHomeService implements HomeService {
  const MockHomeService();

  @override
  Future<CustomerProfile> getProfile(int customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return CustomerProfile(
      id: customerId,
      fullName: 'Nguyễn Văn An',
      phone: '0901234567',
      email: 'nguyenvanan@gmail.com',
      address: '123 Lê Lợi, Q.1, TP.HCM',
    );
  }

  @override
  Future<HomeSummary> getSummary(int customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const HomeSummary(
      vehicleCount: 2,
      upcomingAppointment: '08:30, 28/09/2026',
      activeRepairCount: 1,
      pendingQuotationCount: 1,
      unreadNotificationCount: 2,
    );
  }
}
