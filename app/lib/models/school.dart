class School {
  final String name;
  final String subdomain;
  final String? logoUrl;

  School({required this.name, required this.subdomain, this.logoUrl});

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      name: json['name'] ?? '',
      subdomain: json['subdomain'] ?? '',
      logoUrl: json['logo_url'],
    );
  }

  /// Every subsequent API call for this school is made against this base URL.
  /// This is what makes the SaaS backend switch to the right tenant database.
  String get baseUrl => 'https://$subdomain.scholivax.top';
}
