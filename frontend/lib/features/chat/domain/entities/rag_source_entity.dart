/// One law chunk the backend retrieved for RAG (same as injected into the LLM).
class RagSourceEntity {
  final String? number;
  final String title;
  final String? category;
  final double similarity;
  final String? sourceUrl;

  const RagSourceEntity({
    this.number,
    this.title = '',
    this.category,
    this.similarity = 0,
    this.sourceUrl,
  });

  factory RagSourceEntity.fromJson(Map<String, dynamic> json) {
    final sim = json['similarity'];
    double simVal = 0;
    if (sim is num) {
      simVal = sim.toDouble();
    } else if (sim != null) {
      simVal = double.tryParse(sim.toString()) ?? 0;
    }
    return RagSourceEntity(
      number: json['number'] as String?,
      title: (json['title'] as String?) ?? '',
      category: json['category'] as String?,
      similarity: simVal,
      sourceUrl: json['source_url'] as String?,
    );
  }
}
