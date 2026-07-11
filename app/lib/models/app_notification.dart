class AppNotification {
  final int id;
  final String title;
  final String body;
  final String createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: int.tryParse('${json['id']}') ?? 0,
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        read: json['read_at'] != null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'created_at': createdAt,
        'read_at': read ? createdAt : null,
      };

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
      );
}
