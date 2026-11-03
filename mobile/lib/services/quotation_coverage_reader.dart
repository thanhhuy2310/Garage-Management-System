abstract interface class QuotationCoverageReader {
  Future<Map<String, dynamic>?> getCoverage(String quotationId);
}
