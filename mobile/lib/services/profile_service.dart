import 'customer_api.dart';
export '../demo/profile_demo.dart';
import '../models/customer_profile.dart';

abstract interface class ProfileService {
  Future<CustomerProfile> updateProfile(CustomerProfile profile);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}


class ApiProfileService implements ProfileService {
  ApiProfileService(this.api);
  final CustomerApi api;
  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async => throw StateError('Vui lòng liên hệ lễ tân để cập nhật hồ sơ.');
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await api.request('/auth/change-password', method: 'PUT', body: {'currentPassword': currentPassword, 'newPassword': newPassword});
  }
}
