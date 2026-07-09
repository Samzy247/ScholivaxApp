class Circular {
  final int id;
  final String title;
  final String reference;
  final String content;
  final String date;

  Circular({required this.id, required this.title, required this.reference, required this.content, required this.date});

  factory Circular.fromJson(Map<String, dynamic> json) => Circular(
        id: int.tryParse('${json['circular_id']}') ?? 0,
        title: json['title']?.toString() ?? '',
        reference: json['reference']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'circular_id': id,
        'title': title,
        'reference': reference,
        'content': content,
        'date': date,
      };
}
