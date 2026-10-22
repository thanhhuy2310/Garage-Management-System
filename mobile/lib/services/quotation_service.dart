export '../demo/quotation_demo.dart';
import '../models/quotation.dart';

abstract interface class QuotationService {
  Future<List<Quotation>> getQuotations(int customerId);
  Future<Quotation> updateStatus(String id, QuotationStatus status);
}
