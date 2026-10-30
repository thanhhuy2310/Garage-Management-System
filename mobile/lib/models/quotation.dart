import 'appointment.dart';
import 'vehicle.dart';

enum QuotationStatus { draft, pending, confirmed, rejected }

class QuotationLine {
  const QuotationLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.serverAmount,
    this.kind = 'SERVICE',
  });
  final String name;
  final int quantity;
  final num unitPrice;
  final num? serverAmount;
  final String kind;
  num get amount => serverAmount ?? quantity * unitPrice;
}

class Quotation {
  const Quotation({
    required this.id,
    required this.vehicle,
    required this.service,
    required this.createdAt,
    required this.status,
    required this.lines,
    this.version = 0,
    this.revision = 1,
    this.serverTotal,
    this.rejectionReason,
  });
  final String id;
  final Vehicle vehicle;
  final GarageServiceItem service;
  final DateTime createdAt;
  final QuotationStatus status;
  final List<QuotationLine> lines;
  final int version;
  final int revision;
  final num? serverTotal;
  final String? rejectionReason;
  num get total =>
      serverTotal ?? lines.fold<num>(0, (sum, line) => sum + line.amount);

  Quotation copyWith({QuotationStatus? status}) => Quotation(
    id: id,
    vehicle: vehicle,
    service: service,
    createdAt: createdAt,
    status: status ?? this.status,
    lines: lines,
    version: version,
    revision: revision,
    serverTotal: serverTotal,
    rejectionReason: rejectionReason,
  );
}
