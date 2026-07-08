import '../models/school.dart';
import 'api_client.dart';

class SchoolService {
  static const _mainDomain = 'https://scholivax.top';

  static Future<List<School>> fetchSchools({String? query}) async {
    final data = await ApiClient.get(
      _mainDomain,
      '/api/schools/list',
      query: (query != null && query.trim().isNotEmpty) ? {'q': query.trim()} : null,
    );
    final list = (data['schools'] as List?) ?? [];
    return list.map((e) => School.fromJson(e as Map<String, dynamic>)).toList();
  }
}
