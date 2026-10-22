import 'repair_order.dart' show parseGarageDate;
// TV3-TUAN9
/// Lượt sửa chữa/bảo dưỡng đã hoàn tất, tổng hợp từ dữ liệu nghiệp vụ gốc bởi backend
/// (GET /api/customers/me/history). Không có dữ liệu mock.
enum HistoryCategory { maintenance, repair, mixed }

int _asInt(Object? value) => value is num ? value.round() : 0;

String _asText(Object? value) => value?.toString() ?? '';

DateTime? _asDate(Object? value) =>
    value == null ? null : parseGarageDate(value.toString());

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
    totalCost: json['totalCost'] ?? 0,
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
  final Object totalCost;
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
        unitPrice: json['unitPrice'] ?? 0,
        lineTotal: json['lineTotal'] ?? 0,
      );

  final int serviceId;
  final String name;
  final String type;
  final int quantity;
  final Object unitPrice;
  final Object lineTotal;
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
    unitPrice: json['unitPrice'] ?? 0,
    lineTotal: json['lineTotal'] ?? 0,
  );

  final int partId;
  final String name;
  final int quantity;
  final Object unitPrice;
  final Object lineTotal;
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
      serviceTotal: json['serviceTotal'] ?? 0,
      partsTotal: json['partsTotal'] ?? 0,
    );
  }

  final HistoryItem item;
  final List<HistoryServiceLine> services;
  final List<HistoryPartLine> parts;
  final Object serviceTotal;
  final Object partsTotal;
}

class HistoryPage {
  const HistoryPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory HistoryPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return HistoryPage(
      items: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(HistoryItem.fromJson).toList()
          : <HistoryItem>[],
      page: _asInt(json['page']),
      size: _asInt(json['size']),
      totalElements: _asInt(json['totalElements']),
      totalPages: _asInt(json['totalPages']),
    );
  }

  final List<HistoryItem> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;
}

class HistoryVehicle {
  const HistoryVehicle({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.completedCount,
  });

  factory HistoryVehicle.fromJson(Map<String, dynamic> json) => HistoryVehicle(
    id: _asInt(json['vehicleId']),
    plate: _asText(json['licensePlate']),
    brand: _asText(json['brand']),
    model: _asText(json['model']),
    completedCount: _asInt(json['completedCount']),
  );

  final int id;
  final String plate;
  final String brand;
  final String model;
  final int completedCount;
}
