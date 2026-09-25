class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
  });

  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String address;

  CustomerProfile copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? address,
  }) {
    return CustomerProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}
