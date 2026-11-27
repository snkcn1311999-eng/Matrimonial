import 'dart:convert';
import 'package:flutter/material.dart';
import 'common.dart';
import 'db.dart';

class ProfilesPage extends StatefulWidget {
  final bool recentOnly;
  final bool focusSearch;
  const ProfilesPage(
      {super.key, this.recentOnly = false, this.focusSearch = false});
  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  final searchC = TextEditingController();
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final r = await AppDb.list(
        query: searchC.text, recentOnly: widget.recentOnly);
    if (mounted) setState(() => items = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.recentOnly ? t('recent') : t('view'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchC,
              autofocus: widget.focusSearch,
              onChanged: (_) => load(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: t('search_hint'),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text(t('no_profiles')))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final age = ageFromDob(p['dob'] as String?);
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: gold),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: maroon,
                            child: Icon(
                                p['gender'] == 'male'
                                    ? Icons.man
                                    : Icons.woman,
                                color: cream),
                          ),
                          title: Text(p['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${p['profile_id']} • ${age ?? '-'} ${t('years')} • ${p['district'] ?? ''}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProfileDetailPage(p)),
                            );
                            load();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfileDetailPage extends StatelessWidget {
  final Map<String, dynamic> p;
  const ProfileDetailPage(this.p, {super.key});

  Map<String, dynamic> get extra {
    try {
      return jsonDecode((p['data'] as String?) ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Widget row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: maroon))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('confirm_delete')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('no'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t('yes'))),
        ],
      ),
    );
    if (ok == true) {
      await AppDb.delete(p['id'] as int);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('deleted'))));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = extra;
    final age = ageFromDob(p['dob'] as String?);
    return Scaffold(
      appBar: AppBar(
        title: Text(p['name'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: t('delete'),
            onPressed: () => confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: gold),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  row(t('profile_id'), p['profile_id'] as String?),
                  row(t('name'), p['name'] as String?),
                  row(t('gender'), t((p['gender'] ?? '') as String)),
                  row(t('dob'), showDate(p['dob'] as String?)),
                  row(t('age'), age == null ? null : '$age'),
                  row(t('height'), e['height'] as String?),
                  row(t('marital'), t((e['marital'] ?? '') as String)),
                  row(t('religion'), e['religion'] as String?),
                  row(t('caste'), e['caste'] as String?),
                  row(t('district'), p['district'] as String?),
                  row(t('education'), e['education'] as String?),
                  row(t('profession'), e['profession'] as String?),
                  row(t('mobile'), p['mobile'] as String?),
                  row(t('status'), t((p['status'] ?? '') as String)),
                  row(t('notes'), e['notes'] as String?),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
