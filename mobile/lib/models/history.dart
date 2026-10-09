// TV3-TUAN9
/// Lượt sửa chữa/bảo dưỡng đã hoàn tất, tổng hợp từ dữ liệu nghiệp vụ gốc bởi backend
/// (GET /api/customers/me/history). Không có dữ liệu mock.
enum HistoryCategory { maintenance, repair, mixed }

int _asInt(Object? value) => value is num ? value.round() : 0;

String _asText(Object? value) => value?.toString() ?? '';

DateTime? _asDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

HistoryCategory _asCategory(Object? value) => switch (value?.toString()) {
  'BAO_DUONG' => HistoryCategory.maintenance,
  'BAO_DUONG_SUA_CHUA' => HistoryCategory.mixed,
  _ => HistoryCategory.repair,
};

class HistoryItem {
  const HistoryItem({
    required this.repairOrderId,
    required this.vehicleId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.category,
    required this.summary,
    required this.serviceCount,
    required this.partCount,
    required this.totalCost,
    required this.result,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    repairOrderId: _asInt(json['repairOrderId']),
    vehicleId: _asInt(json['vehicleId']),
    plate: _asText(json['licensePlate']),
    brand: _asText(json['brand']),
    model: _asText(json['model']),
    category: _asCategory(json['category']),
    summary: _asText(json['summary']),
    serviceCount: _asInt(json['serviceCount']),
    partCount: _asInt(json['partCount']),
    totalCost: _asInt(json['totalCost']),
    result: _asText(json['result']),
    createdAt: _asDate(json['createdAt']),
    startedAt: _asDate(json['startedAt']),
    completedAt: _asDate(json['completedAt']),
  );

  final int repairOrderId;
  final int vehicleId;
  final String plate;
  final String brand;
  final String model;
  final HistoryCategory category;
  final String summary;
  final int serviceCount;
  final int partCount;
  final int totalCost;
  final String result;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  String get vehicleName => [brand, model].where((part) => part.isNotEmpty).join(' ');

  /// Ngày hiển thị: hoàn thành, nếu chưa có thì bắt đầu, rồi đến ngày lập phiếu.
  DateTime? get date => completedAt ?? startedAt ?? createdAt;
}

class HistoryServiceLine {
  const HistoryServiceLine({
    required this.serviceId,
    required this.name,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory HistoryServiceLine.fromJson(Map<String, dynamic> json) =>
      HistoryServiceLine(
        serviceId: _asInt(json['serviceId']),
        name: _asText(json['name']),
        type: _asText(json['type']),
        quantity: _asInt(json['quantity']),
        unitPrice: _asInt(json['unitPrice']),
        lineTotal: _asInt(json['lineTotal']),
      );

  final int serviceId;
  final String name;
  final String type;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
}

class HistoryPartLine {
  const HistoryPartLine({
    required this.partId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory HistoryPartLine.fromJson(Map<String, dynamic> json) => HistoryPartLine(
    partId: _asInt(json['partId']),
    name: _asText(json['name']),
    quantity: _asInt(json['quantity']),
    unitPrice: _asInt(json['unitPrice']),
    lineTotal: _asInt(json['lineTotal']),
  );

  final int partId;
  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
}

class HistoryDetail {
  const HistoryDetail({
    required this.item,
    required this.services,
    required this.parts,
    required this.serviceTotal,
    required this.partsTotal,
  });

  factory HistoryDetail.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Thiếu thông tin phiếu sửa chữa.');
    }
    List<T> lines<T>(Object? raw, T Function(Map<String, dynamic>) parse) =>
        raw is List ? raw.whereType<Map<String, dynamic>>().map(parse).toList() : <T>[];
    return HistoryDetail(
      item: HistoryItem.fromJson(item),
      services: lines(json['services'], HistoryServiceLine.fromJson),
      parts: lines(json['parts'], HistoryPartLine.fromJson),
      serviceTotal: _asInt(json['serviceTotal']),
      partsTotal: _asInt(json['partsTotal']),
    );
  }

  final HistoryItem item;
  final List<HistoryServiceLine> services;
  final List<HistoryPartLine> parts;
  final int serviceTotal;
  final int partsTotal;
}
