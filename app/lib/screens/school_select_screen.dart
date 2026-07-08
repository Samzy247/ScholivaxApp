import 'package:flutter/material.dart';
import '../models/school.dart';
import '../services/api_client.dart';
import '../services/school_service.dart';
import '../widgets/no_internet_view.dart';
import 'role_select_screen.dart';

class SchoolSelectScreen extends StatefulWidget {
  const SchoolSelectScreen({super.key});

  @override
  State<SchoolSelectScreen> createState() => _SchoolSelectScreenState();
}

class _SchoolSelectScreenState extends State<SchoolSelectScreen> {
  late Future<List<School>> _future;
  List<School> _all = [];
  List<School> _filtered = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = SchoolService.fetchSchools().then((schools) {
        _all = schools;
        _filtered = schools;
        return schools;
      });
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _filtered = _all
          .where((s) => s.name.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your School')),
      body: FutureBuilder<List<School>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error is NoConnectionException) {
              return NoInternetView(onRetry: _load);
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load schools.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search for your school',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? ListView(
                          // ListView so pull-to-refresh still works on an empty result.
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(child: Text('No matching schools found.')),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final school = _filtered[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEEF2FF),
                                backgroundImage: school.logoUrl != null
                                    ? NetworkImage(school.logoUrl!)
                                    : null,
                                child: school.logoUrl == null
                                    ? const Icon(Icons.school, color: Color(0xFF3730A3))
                                    : null,
                              ),
                              title: Text(school.name),
                              subtitle: Text('${school.subdomain}.scholivax.top'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RoleSelectScreen(school: school),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
