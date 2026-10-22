class HomeSummary {
  const HomeSummary({
    this.hasConnectedCustomerExperience = true,
    required this.vehicleCount,
    required this.upcomingAppointment,
    required this.activeRepairCount,
    required this.pendingQuotationCount,
    required this.unreadNotificationCount,
  });

  final bool hasConnectedCustomerExperience;
  final int vehicleCount;
  final String? upcomingAppointment;
  final int activeRepairCount;
  final int pendingQuotationCount;
  final int unreadNotificationCount;
}
