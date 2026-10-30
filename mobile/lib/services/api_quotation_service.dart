import '../models/appointment.dart';
import '../models/quotation.dart';
import '../models/vehicle.dart';
import 'customer_api.dart';
import 'quotation_service.dart';

class ApiQuotationService implements QuotationService {
  ApiQuotationService(this.api);
  final CustomerApi api;

  static Quotation fromJson(Map<String, dynamic> data) {
    final lines = (data['lines'] as List)
        .map(
          (line) => QuotationLine(
            name: line['name'] as String,
            quantity: line['quantity'] as int,
            unitPrice: line['unitPrice'] as num,
            serverAmount: line['amount'] as num,
            kind: line['kind'] as String,
          ),
        )
        .toList();
    return Quotation(
      id: data['id'].toString(),
      vehicle: Vehicle(
        id: data['vehicleId'] as int,
        customerId: data['customerId'] as int,
        plate: data['plate'] as String,
        brand: data['brand'] as String? ?? '',
        model: data['model'] as String? ?? '',
        year: data['year'] as int?,
        mileage: data['mileage'] as int?,
      ),
      service: GarageServiceItem(
        id: 0,
        name: 'Phiếu sửa chữa ${data['repairOrderId']}',
        category: '',
        price: 0,
        description: '',
      ),
      createdAt: DateTime.parse(data['createdAt'] as String),
      status: switch (data['status']) {
        'NHAP' => QuotationStatus.draft,
        'CHO_XAC_NHAN' => QuotationStatus.pending,
        'DA_XAC_NHAN' => QuotationStatus.confirmed,
        'KHONG_DONG_Y' => QuotationStatus.rejected,
        _ => throw FormatException(
          'Trạng thái báo giá không được hỗ trợ: ${data['status']}',
        ),
      },
      lines: lines,
      version: data['version'] as int,
      revision: data['revision'] as int,
      serverTotal: data['total'] as num,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  @override
  Future<List<Quotation>> getQuotations(int customerId) async {
    final response = await api.request('/quotations') as List;
    return response
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Quotation> updateStatus(
    String id,
    QuotationStatus status, {
    int? version,
    String? reason,
  }) async {
    if (version == null) {
      throw StateError('Cần tải báo giá trước khi xác nhận.');
    }
    if (status != QuotationStatus.confirmed &&
        status != QuotationStatus.rejected) {
      throw StateError('Khách hàng chỉ được chấp thuận hoặc từ chối báo giá.');
    }
    final response = await api.request(
      '/quotations/$id/decision',
      method: 'POST',
      body: {
        'version': version,
        'accepted': status == QuotationStatus.confirmed,
        'reason': reason,
      },
    ) as Map<String, dynamic>;
    return fromJson(response);
  }
}
