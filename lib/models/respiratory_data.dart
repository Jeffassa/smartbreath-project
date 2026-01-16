class AnalysisResult {
  final int dataId;
  final String status;
  final double riskScore;
  final String recommendation;

  AnalysisResult({
    required this.dataId,
    required this.status,
    required this.riskScore,
    required this.recommendation,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      dataId: json['data_id'],
      status: json['status'],
      riskScore: (json['risk_score'] as num).toDouble(),
      recommendation: json['recommendation'],
    );
  }
}