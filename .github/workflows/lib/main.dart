import 'package:flutter/material.dart';

void main() => runApp(const MatrimonialApp());

const maroon = Color(0xFF800000);
const cream = Color(0xFFFFF8E7);
const gold = Color(0xFFC9A227);

const Map<String, Map<String, String>> strings = {
  'en': {
    'title': 'Matrimonial Office',
    'username': 'Username',
    'password': 'Password',
    'login': 'Login',
    'logout': 'Logout',
    'wrong': 'Wrong username or password',
    'total': 'Total Profiles',
    'male': 'Male',
    'female': 'Female',
    'newly': 'Newly Added',
    'married': 'Married',
    'pending': 'Pending',
    'add': 'Add New Profile',
    'view': 'View All Profiles',
    'search': 'Search Profile',
    'recent': 'Recently Added',
    'settings': 'Settings',
    'soon': 'Coming soon',
    'language': 'தமிழ்',
  },
  'ta': {
    'title': 'திருமண தகவல் மையம்',
    'username': 'பயனர் பெயர்',
    'password': 'கடவுச்சொல்',
    'login': 'உள்நுழை',
    'logout': 'வெளியேறு',
    'wrong': 'பயனர் பெயர் அல்லது கடவுச்சொல் தவறு',
    'total': 'மொத்த விவரங்கள்',
    'male': 'ஆண்',
    'female': 'பெண்',
    'newly': 'புதியவை',
    'married': 'திருமணமானவர்',
    'pending': 'நிலுவையில்',
    'add': 'புதிய விவரம் சேர்க்க',
    'view': 'விவரங்களை பார்க்க',
    'search': 'தேடுக',
    'recent': 'சமீபத்தில் சேர்த்தவை',
    'settings': 'அமைப்புகள்',
    'soon': 'விரைவில்',
    'language': 'English',
  },
};

class MatrimonialApp extends StatefulWidget {
  const MatrimonialApp({super.key});
  @override
  State<MatrimonialApp> createState() => _MatrimonialAppState();
}

class _MatrimonialAppState extends State<MatrimonialApp> {
  String lang = 'ta';
  bool loggedIn = false;

  String t(String key) => strings[lang]![key]!;

  void toggleLang() => setState(() => lang = lang == 'ta' ? 'en' : 'ta');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Matrimonial Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: maroon, primary: maroon, secondary: gold),
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
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: loggedIn
          ? DashboardPage(t: t, onToggleLang: toggleLang, onLogout: () => setState(() => loggedIn = false))
          : LoginPage(t: t, onToggleLang: toggleLang, onSuccess: () => setState(() => loggedIn = true)),
    );
  }
}

class LoginPage extends StatefulWidget {
  final String Function(String) t;
  final VoidCallback onToggleLang;
  final VoidCallback onSuccess;
  const LoginPage({super.key, required this.t, required this.onToggleLang, required this.onSuccess});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  void submit() {
    // TEMPORARY placeholder login (admin / admin123). Stage 1 replaces this
    // with a secure, stored-hash login.
    if (userCtrl.text.trim() == 'admin' && passCtrl.text == 'admin123') {
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.t('wrong'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('title')),
        actions: [TextButton(onPressed: widget.onToggleLang, child: Text(t('language'), style: const TextStyle(color: gold, fontSize: 16)))],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Icon(Icons.favorite, size: 72, color: maroon),
                const SizedBox(height: 24),
                TextField(
                  controller: userCtrl,
                  decoration: InputDecoration(labelText: t('username'), border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: t('password'), border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: submit, child: Text(t('login'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final String Function(String) t;
  final VoidCallback onToggleLang;
  final VoidCallback onLogout;
  const DashboardPage({super.key, required this.t, required this.onToggleLang, required this.onLogout});

  Widget stat(String label, String value) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: gold)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: maroon)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget bigButton(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('soon')))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('title')),
        actions: [
          TextButton(onPressed: onToggleLang, child: Text(t('language'), style: const TextStyle(color: gold, fontSize: 16))),
          IconButton(icon: const Icon(Icons.logout), tooltip: t('logout'), onPressed: onLogout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              stat(t('total'), '0'),
              stat(t('male'), '0'),
              stat(t('female'), '0'),
              stat(t('newly'), '0'),
              stat(t('married'), '0'),
              stat(t('pending'), '0'),
            ],
          ),
          const SizedBox(height: 20),
          bigButton(context, Icons.person_add, t('add')),
          bigButton(context, Icons.list_alt, t('view')),
          bigButton(context, Icons.search, t('search')),
          bigButton(context, Icons.history, t('recent')),
          bigButton(context, Icons.settings, t('settings')),
        ],
      ),
    );
  }
}
