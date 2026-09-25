class UserSession {
  const UserSession({
    required this.accessToken,
    required this.accountId,
    required this.username,
    required this.customerId,
  });

  final String accessToken;
  final int accountId;
  final String username;
  final int customerId;
}
