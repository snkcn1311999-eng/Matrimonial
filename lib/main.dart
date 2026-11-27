import 'package:flutter/material.dart';
import 'common.dart';
import 'db.dart';
import 'photo_store.dart';
import 'add_profile_page.dart';
import 'profiles_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhotoStore.init();
  runApp(const MatrimonialApp());
}

class MatrimonialApp extends StatelessWidget {
  const MatrimonialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Matrimonial App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: maroon, primary: maroon, secondary: gold),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          backgroundColor: maroon,
          foregroundColor: cream,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: maroon,
            foregroundColor: cream,
            minimumSize: const Size.fromHeight(60),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, int> stats = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final s = await AppDb.stats();
    if (mounted) setState(() => stats = s);
  }

  Future<void> open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    load();
  }

  Widget header() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold, width: 1.5),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 84,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.favorite, size: 60, color: maroon),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'ஸ்ரீ சுபமங்கலம் திருமண தகவல் மையம்',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: maroon,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget stat(String key, String label) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: gold),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${stats[key] ?? 0}',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: maroon)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget bigButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: langNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Matrimonial App'),
            actions: [
              TextButton(
                onPressed: () => langNotifier.value =
                    langNotifier.value == 'ta' ? 'en' : 'ta',
                child: Text(t('language'),
                    style: const TextStyle(color: gold, fontSize: 16)),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              header(),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.95,
                children: [
                  stat('total', t('total')),
                  stat('male', t('male')),
                  stat('female', t('female')),
                  stat('newly', t('newly')),
                  stat('married', t('married')),
                  stat('pending', t('pending')),
                ],
              ),
              const SizedBox(height: 20),
              bigButton(Icons.person_add, t('add'),
                  () => open(const AddProfilePage())),
              bigButton(Icons.list_alt, t('view'),
                  () => open(const ProfilesPage())),
              bigButton(Icons.search, t('search'),
                  () => open(const ProfilesPage(focusSearch: true))),
              bigButton(Icons.history, t('recent'),
                  () => open(const ProfilesPage(recentOnly: true))),
              bigButton(
                  Icons.settings,
                  t('settings'),
                  () => ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(t('soon'))))),
            ],
          ),
        );
      },
    );
  }
}
