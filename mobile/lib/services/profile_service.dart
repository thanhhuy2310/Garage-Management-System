import '../models/customer_profile.dart';

abstract interface class ProfileService {
  Future<CustomerProfile> updateProfile(CustomerProfile profile);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

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
