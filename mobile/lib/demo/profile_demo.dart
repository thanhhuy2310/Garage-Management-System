// MOCK_ONLY: in-memory demo, never persisted to the garage.
import '../models/customer_profile.dart';
import '../services/profile_service.dart';

class MockProfileService implements ProfileService {
  @override
  Future<CustomerProfile> updateProfile(CustomerProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return profile;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (currentPassword == 'sai') {
      throw StateError('Mật khẩu hiện tại không đúng.');
    }
  }
}
