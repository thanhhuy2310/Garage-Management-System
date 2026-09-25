import 'appointment.dart';
import 'vehicle.dart';

enum QuotationStatus { draft, pending, confirmed, rejected }

class QuotationLine {
  const QuotationLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });
  final String name;
  final int quantity;
  final int unitPrice;
  int get amount => quantity * unitPrice;
}

class Quotation {
  const Quotation({
    required this.id,
    required this.vehicle,
    required this.service,
    required this.createdAt,
    required this.status,
    required this.lines,
  });
  final String id;
  final Vehicle vehicle;
  final GarageServiceItem service;
  final DateTime createdAt;
  final QuotationStatus status;
  final List<QuotationLine> lines;
  int get total => lines.fold(0, (sum, line) => sum + line.amount);

  Quotation copyWith({QuotationStatus? status}) => Quotation(
    id: id,
    vehicle: vehicle,
    service: service,
    createdAt: createdAt,
    status: status ?? this.status,
    lines: lines,
  );
}
