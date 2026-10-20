// ENOUGH — AI Life Operating System
// Bitta fayl, tashqi paketlarsiz (faqat Flutter SDK).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const EnoughApp());

// ───────────────────────── Ranglar va sozlamalar ─────────────────────────
const kBg = Color(0xFF0B0F1A);
const kSurface = Color(0xFF141A2B);
const kSurface2 = Color(0xFF1B2338);
const kViolet = Color(0xFF7C5CFF);
const kBlue = Color(0xFF3D7BFF);
const kNavy = Color(0xFF0C447C);
const kRed = Color(0xFFC0392B);
const kText = Color(0xFFEDEFF7);
const kMuted = Color(0xFF8A93AD);

// AI Coach uchun model nomi (Settings'da API kalit kiritilganda ishlaydi)
const kModel = 'claude-sonnet-5-5';

// ───────────────────────── Kategoriyalar ─────────────────────────
class Cat {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> subs;
  const Cat(this.name, this.icon, this.color, this.subs);
}

const List<Cat> kCats = [
  Cat('Personal growth', Icons.spa, Color(0xFF1FA67A),
      ['Kundalik', "Kitob o'qish", "Ko'nikmalar", 'Refleksiya']),
  Cat('Productivity', Icons.checklist, Color(0xFF3D8BEA),
      ['Vazifalar', 'Fokus vaqti', 'Loyihalar', 'Vaqt bloklari']),
  Cat('Learning', Icons.menu_book, Color(0xFFE0663F),
      ['Kurslar', "O'qish ro'yxati", 'Qaydlar', 'Testlar']),
  Cat('Health', Icons.favorite, Color(0xFF5FAE2E),
      ['Uyqu', 'Mashqlar', 'Ovqatlanish', 'Suv']),
  Cat('Finance', Icons.savings, Color(0xFFE0A030),
      ['Byudjet', 'Xarajatlar', "Jamg'arma", 'Daromad']),
  Cat('Mindset', Icons.psychology, Color(0xFF8E7CFF),
      ['Meditatsiya', 'Minnatdorchilik', 'Affirmatsiya', 'Kayfiyat']),
  Cat('Relationships', Icons.people, Color(0xFFE0608E),
      ['Kontaktlar', 'Uchrashuvlar', "Xabar yo'llash", 'Muhim sanalar']),
  Cat('Spiritual', Icons.nightlight_round, Color(0xFF9AA3B8),
      ['Ibodat / sokinlik', 'Refleksiya', "O'qish", 'Minnatdorchilik']),
];

// ───────────────────────── Ma'lumot modellari ─────────────────────────
class Goal {
  String title;
  int cat;
  double progress;
  Goal(this.title, this.cat, [this.progress = 0]);
}

class Task {
  String title;
  int cat;
  bool done;
  Task(this.title, this.cat, [this.done = false]);
}

class Habit {
  String title;
  int cat;
  bool done;
  int streak;
  Habit(this.title, this.cat, [this.done = false, this.streak = 0]);
}

class ChatMsg {
  final bool me;
  final String text;
  ChatMsg(this.me, this.text);
}

class AppState extends ChangeNotifier {
  static final AppState I = AppState._();
  AppState._() {
    _seed();
  }

  String name = 'Do\'st';
  String apiKey = '';
  final List<Goal> goals = [];
  final List<Task> tasks = [];
  final List<Habit> habits = [];
  final List<ChatMsg> chat = [];

  void _seed() {
    for (var i = 0; i < kCats.length; i++) {
      for (final s in kCats[i].subs) {
        habits.add(Habit(s, i));
      }
    }
    goals.add(Goal('Har kuni 30 daqiqa mashq', 3, 0.3));
    goals.add(Goal("3 oylik jamg'arma fondi", 4, 0.15));
    goals.add(Goal('Ayiga 2 ta kitob', 2, 0.5));
    tasks.add(Task('Haftalik rejani tuzish', 1));
    tasks.add(Task("Bugun 20 bet kitob o'qish", 0));
    tasks.add(Task('Xarajatlarni yozib chiqish', 4));
    chat.add(ChatMsg(false,
        "Salom! Men ENOUGH AI Coach'iman. Odatlaringni kuzataman, holatingni tahlil qilaman va keyingi qadamni aytaman. Nimadan boshlaymiz?"));
  }

  void reset() {
    goals.clear();
    tasks.clear();
    habits.clear();
    chat.clear();
    _seed();
    notifyListeners();
  }

  void ping() => notifyListeners();

  void toggleHabit(Habit h) {
    h.done = !h.done;
    h.streak = h.done ? h.streak + 1 : math.max(0, h.streak - 1);
    notifyListeners();
  }

  double catScore(int c) {
    final hs = habits.where((h) => h.cat == c).toList();
    final ts = tasks.where((t) => t.cat == c).toList();
    final total = hs.length + ts.length;
    if (total == 0) return 0;
    final done = hs.where((h) => h.done).length + ts.where((t) => t.done).length;
    return done / total;
  }

  double get overall {
    final total = habits.length + tasks.length;
    if (total == 0) return 0;
    final done =
        habits.where((h) => h.done).length + tasks.where((t) => t.done).length;
    return done / total;
  }

  int get weakestCat {
    var weak = 0;
    var ws = 2.0;
    for (var i = 0; i < kCats.length; i++) {
      final sc = catScore(i);
      if (sc < ws) {
        ws = sc;
        weak = i;
      }
    }
    return weak;
  }

  int get bestStreak {
    var b = 0;
    for (final h in habits) {
      if (h.streak > b) b = h.streak;
    }
    return b;
  }
}

// ───────────────────────── AI Coach mantiqi ─────────────────────────
String localCoach(String q) {
  final s = AppState.I;
  final low = q.toLowerCase();
  final pct = (s.overall * 100).round();
  final weak = s.weakestCat;
  final wp = (s.catScore(weak) * 100).round();
  final openTasks = s.tasks.where((t) => !t.done).length;

  if (low.contains('motiv') || low.contains('charch') || low.contains('hafsala')) {
    return "Eslatma: mukammallik shart emas — izchillik kerak. Bugun $pct% bajarding. "
        "Eng kichik qadamni tanla: ${kCats[weak].name} bo'limidan bitta odatni belgila. "
        "5 daqiqa ham yetarli. ENOUGH degani — bugungi qadam yetarli bo'lishi.";
  }
  if (low.contains('reja') || low.contains('maqsad')) {
    return "Reja taklifi:\n1) Bugun ${kCats[weak].name} bo'limidan 1 ta odat.\n"
        "2) Ochiq $openTasks ta vazifadan eng muhimini birinchi bajar.\n"
        "3) Kechqurun 2 daqiqa refleksiya: nima ishladi, nima ishlamadi?";
  }
  if (low.contains('tahlil') || low.contains('holat') || low.contains('natija')) {
    return "Umumiy progress: $pct%. Eng kuchsiz yo'nalish: ${kCats[weak].name} ($wp%). "
        "Eng uzun seriya: ${s.bestStreak} kun. "
        "${pct >= 60 ? "Yaxshi sur'at — shuni saqla." : "Sur'atni oshirish uchun kuniga 2–3 ta kichik odatga e'tibor ber."}";
  }
  if (low.contains('intizom') || low.contains('odat')) {
    return "Intizom — motivatsiya emas, tizim. Odatni bir joyga va bir vaqtga bog'la "
        "(masalan, qahvadan keyin 10 daqiqa o'qish). Hozir eng kuchsizing: ${kCats[weak].name}.";
  }
  return "Hozirgi holat: $pct% bajarilgan, ochiq vazifalar: $openTasks. "
      "Keyingi qadam: ${kCats[weak].name} bo'limidan bitta odatni belgila. "
      "Savol ber: \"tahlil\", \"reja\" yoki \"motivatsiya\".";
}

String _systemPrompt() {
  final s = AppState.I;
  final weak = s.weakestCat;
  final lines = StringBuffer();
  for (var i = 0; i < kCats.length; i++) {
    lines.write('${kCats[i].name}: ${(s.catScore(i) * 100).round()}%; ');
  }
  return "Sen ENOUGH ilovasining AI Coach'isan. Foydalanuvchi ismi: ${s.name}. "
      "O'zbek tilida, qisqa (5-7 gap), aniq, do'stona lekin talabchan javob ber. "
      "Oddiy chatbot emas — tahlil qil, odatlarni kuzat, aniq keyingi qadamni ayt, intizomga chaqir. "
      "Foydalanuvchi holati: umumiy ${(s.overall * 100).round()}%. $lines"
      "Eng kuchsiz yo'nalish: ${kCats[weak].name}. Eng uzun seriya: ${s.bestStreak} kun.";
}

Future<String> claudeReply(String q) async {
  final s = AppState.I;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final req = await client
        .postUrl(Uri.parse('https://api.anthropic.com/v1/messages'));
    req.headers.set('content-type', 'application/json');
    req.headers.set('x-api-key', s.apiKey);
    req.headers.set('anthropic-version', '2023-06-01');
    req.add(utf8.encode(jsonEncode({
      'model': kModel,
      'max_tokens': 600,
      'system': _systemPrompt(),
      'messages': [
        {'role': 'user', 'content': q}
      ],
    })));
    final res = await req.close().timeout(const Duration(seconds: 40));
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw Exception(body);
    final j = jsonDecode(body) as Map<String, dynamic>;
    final parts = (j['content'] as List)
        .whereType<Map>()
        .where((m) => m['type'] == 'text')
        .map((m) => m['text'].toString());
    final out = parts.join('\n').trim();
    return out.isEmpty ? localCoach(q) : out;
  } finally {
    client.close();
  }
}

// ───────────────────────── Ilova ─────────────────────────
Route<dynamic> fadeRoute(Widget w) => PageRouteBuilder<dynamic>(
      pageBuilder: (_, __, ___) => w,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    );

class EnoughApp extends StatelessWidget {
  const EnoughApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ENOUGH',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kViolet,
          secondary: kBlue,
          surface: kSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kSurface,
          indicatorColor: kViolet.withAlpha(70),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

// ───────────────────────── Progress halqa (logotip) ─────────────────────────
class RingPainter extends CustomPainter {
  final double value; // 0..1
  final double stroke;
  final double maxSweep;
  RingPainter(this.value, this.stroke, this.maxSweep);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - stroke * 1.5;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0xFF232C45),
    );

    final sweep = maxSweep * value;
    if (sweep < 0.05) return;

    final shader = SweepGradient(
      startAngle: 0,
      endAngle: math.max(0.2, sweep),
      colors: const [kRed, kViolet, kBlue],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );

    // strelka (chiziq oxirida)
    final a = -math.pi / 2 + sweep;
    final nor = Offset(math.cos(a), math.sin(a));
    final tan = Offset(-math.sin(a), math.cos(a));
    final pt = c + nor * r;
    final tip = pt + tan * (stroke * 1.5);
    final b1 = pt + nor * (stroke * 0.9);
    final b2 = pt - nor * (stroke * 0.9);
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = kBlue);
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.value != value || old.stroke != stroke || old.maxSweep != maxSweep;
}

class LogoMark extends StatelessWidget {
  final double size;
  final double progress;
  const LogoMark({super.key, this.size = 160, this.progress = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: RingPainter(progress, size * 0.055, 5.2),
        child: Center(
          child: Container(
            width: size * 0.36,
            height: size * 0.36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: kNavy),
            child: Text(
              'e',
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Splash ─────────────────────────
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().then((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(const LoginPage()));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_c.value);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LogoMark(size: 180, progress: t),
                const SizedBox(height: 28),
                Opacity(
                  opacity: t,
                  child: const Text(
                    'ENOUGH',
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: 8),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: t,
                  child: const Text('AI Life Operating System',
                      style: TextStyle(color: kMuted, letterSpacing: 1)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── Login ─────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: kMuted),
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  void _go() {
    final n = _name.text.trim();
    AppState.I.name = n.isEmpty ? "Do'st" : n;
    Navigator.of(context).pushReplacement(fadeRoute(const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const LogoMark(size: 110),
                const SizedBox(height: 20),
                const Text('Xush kelibsan',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text("Hayotingni bitta joyda boshqar",
                    style: TextStyle(color: kMuted)),
                const SizedBox(height: 30),
                TextField(controller: _name, decoration: _dec('Ismingiz', Icons.person_outline)),
                const SizedBox(height: 14),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Email (ixtiyoriy)', Icons.mail_outline),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kViolet,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _go,
                    child: const Text('Boshlash',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Home ─────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _i = 0;
  final _pages = const [
    DashboardPage(),
    GoalsPage(),
    TasksPage(),
    CoachPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _i, children: _pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Asosiy'),
          NavigationDestination(
              icon: Icon(Icons.flag_outlined),
              selectedIcon: Icon(Icons.flag),
              label: 'Maqsadlar'),
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Vazifalar'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Coach'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Sozlamalar'),
        ],
      ),
    );
  }
}

// ───────────────────────── Dashboard ─────────────────────────
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final s = AppState.I;
        final pct = (s.overall * 100).round();
        final doneHabits = s.habits.where((h) => h.done).length;
        final openTasks = s.tasks.where((t) => !t.done).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Text('Salom, ${s.name}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text("Bugun o'zingdan ustun bo'l",
                style: TextStyle(color: kMuted)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kViolet.withAlpha(60)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 118,
                    height: 118,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: s.overall),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => CustomPaint(
                        painter: RingPainter(v, 9, 6.0),
                        child: Center(
                          child: Text('$pct%',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bugungi progress',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 10),
                        _stat(Icons.local_fire_department, kRed,
                            'Eng uzun seriya: ${s.bestStreak} kun'),
                        const SizedBox(height: 6),
                        _stat(Icons.check_circle, kViolet,
                            'Odatlar: $doneHabits/${s.habits.length}'),
                        const SizedBox(height: 6),
                        _stat(Icons.task_alt, kBlue, 'Ochiq vazifalar: $openTasks'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurface2,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: kViolet),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Coach: eng kuchsiz yo'nalishing — ${kCats[s.weakestCat].name}. "
                      "Bugun undan bitta odatni belgila.",
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('Kategoriyalar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                for (var i = 0; i < kCats.length; i++) _CatTile(index: i),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _stat(IconData icon, Color color, String text) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text, style: const TextStyle(color: kMuted, fontSize: 13))),
        ],
      );
}

class _CatTile extends StatelessWidget {
  final int index;
  const _CatTile({required this.index});

  @override
  Widget build(BuildContext context) {
    final c = kCats[index];
    final score = AppState.I.catScore(index);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => CategoryPage(index: index))),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.color.withAlpha(70)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.color.withAlpha(45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(c.icon, color: c.color, size: 22),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: score,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(6),
                      color: c.color,
                      backgroundColor: kSurface2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Kategoriya sahifasi ─────────────────────────
class CategoryPage extends StatelessWidget {
  final int index;
  const CategoryPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = kCats[index];
    return Scaffold(
      appBar: AppBar(title: Text(c.name)),
      body: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final s = AppState.I;
          final habits = s.habits.where((h) => h.cat == index).toList();
          final goals = s.goals.where((g) => g.cat == index).toList();
          final tasks = s.tasks.where((t) => t.cat == index).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.color.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(c.icon, color: c.color, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${(s.catScore(index) * 100).round()}% bajarildi',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: s.catScore(index),
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(6),
                            color: c.color,
                            backgroundColor: kSurface2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Odatlar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final h in habits)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    onTap: () => s.toggleHabit(h),
                    leading: Icon(
                      h.done ? Icons.check_circle : Icons.circle_outlined,
                      color: h.done ? c.color : kMuted,
                    ),
                    title: Text(h.title),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 16, color: kRed),
                        const SizedBox(width: 3),
                        Text('${h.streak}', style: const TextStyle(color: kMuted)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              const Text('Maqsadlar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (goals.isEmpty)
                const Text("Bu bo'limda hali maqsad yo'q. 'Maqsadlar' sahifasidan qo'sh.",
                    style: TextStyle(color: kMuted)),
              for (final g in goals) GoalCard(goal: g),
              const SizedBox(height: 14),
              const Text('Vazifalar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                const Text("Bu bo'limda hali vazifa yo'q.",
                    style: TextStyle(color: kMuted)),
              for (final t in tasks)
                CheckboxListTile(
                  value: t.done,
                  activeColor: c.color,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(t.title,
                      style: TextStyle(
                          decoration: t.done ? TextDecoration.lineThrough : null,
                          color: t.done ? kMuted : kText)),
                  onChanged: (v) {
                    t.done = v ?? false;
                    s.ping();
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────── Qo'shish dialogi ─────────────────────────
Future<void> showAddDialog(
    BuildContext context, String title, void Function(String, int) onAdd) async {
  final ctl = TextEditingController();
  var cat = 0;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: kSurface2,
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Nomi'),
            ),
            const SizedBox(height: 14),
            DropdownButton<int>(
              value: cat,
              isExpanded: true,
              dropdownColor: kSurface2,
              items: [
                for (var i = 0; i < kCats.length; i++)
                  DropdownMenuItem<int>(value: i, child: Text(kCats[i].name)),
              ],
              onChanged: (v) => setS(() => cat = v ?? 0),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          FilledButton(
            onPressed: () {
              final t = ctl.text.trim();
              if (t.isNotEmpty) onAdd(t, cat);
              Navigator.pop(ctx);
            },
            child: const Text("Qo'shish"),
          ),
        ],
      ),
    ),
  );
  ctl.dispose();
}

// ───────────────────────── Maqsadlar ─────────────────────────
class GoalCard extends StatelessWidget {
  final Goal goal;
  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    final c = kCats[goal.cat];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(c.icon, color: c.color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(goal.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, color: kMuted, size: 20),
                onPressed: () {
                  s.goals.remove(goal);
                  s.ping();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: goal.progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            color: c.color,
            backgroundColor: kSurface2,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(goal.progress * 100).round()}%',
                  style: const TextStyle(color: kMuted)),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      goal.progress = (goal.progress - 0.1).clamp(0.0, 1.0);
                      s.ping();
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.add_circle, color: c.color),
                    onPressed: () {
                      goal.progress = (goal.progress + 0.1).clamp(0.0, 1.0);
                      s.ping();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: kViolet,
        foregroundColor: Colors.white,
        onPressed: () => showAddDialog(context, 'Yangi maqsad', (t, c) {
          AppState.I.goals.add(Goal(t, c));
          AppState.I.ping();
        }),
        icon: const Icon(Icons.add),
        label: const Text('Maqsad'),
      ),
      body: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final goals = AppState.I.goals;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
            children: [
              const Text('Maqsadlar',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              if (goals.isEmpty)
                const Text("Hali maqsad yo'q. Pastdagi tugma bilan qo'sh.",
                    style: TextStyle(color: kMuted)),
              for (final g in goals) GoalCard(goal: g),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────── Vazifalar ─────────────────────────
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        backgroundColor: kViolet,
        foregroundColor: Colors.white,
        onPressed: () => showAddDialog(context, 'Yangi vazifa', (t, c) {
          AppState.I.tasks.add(Task(t, c));
          AppState.I.ping();
        }),
        icon: const Icon(Icons.add),
        label: const Text('Vazifa'),
      ),
      body: ListenableBuilder(
        listenable: AppState.I,
        builder: (context, _) {
          final s = AppState.I;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
            children: [
              const Text('Vazifalar',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text("O'chirish uchun chapga surib yubor",
                  style: TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 12),
              if (s.tasks.isEmpty)
                const Text("Hali vazifa yo'q.", style: TextStyle(color: kMuted)),
              for (final t in s.tasks)
                Dismissible(
                  key: ObjectKey(t),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: kRed.withAlpha(120),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline),
                  ),
                  onDismissed: (_) {
                    s.tasks.remove(t);
                    s.ping();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: CheckboxListTile(
                      value: t.done,
                      activeColor: kCats[t.cat].color,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(t.title,
                          style: TextStyle(
                              decoration:
                                  t.done ? TextDecoration.lineThrough : null,
                              color: t.done ? kMuted : kText)),
                      subtitle: Text(kCats[t.cat].name,
                          style: TextStyle(color: kCats[t.cat].color, fontSize: 12)),
                      onChanged: (v) {
                        t.done = v ?? false;
                        s.ping();
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────── AI Coach ─────────────────────────
class CoachPage extends StatefulWidget {
  const CoachPage({super.key});
  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  bool _busy = false;

  @override
  void dispose() {
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _busy) return;
    final s = AppState.I;
    _ctl.clear();
    s.chat.add(ChatMsg(true, q));
    setState(() => _busy = true);
    s.ping();
    _scrollDown();

    String a;
    if (s.apiKey.isNotEmpty) {
      try {
        a = await claudeReply(q);
      } catch (e) {
        a = "${localCoach(q)}\n\n(AI serverga ulanib bo'lmadi — internet yoki API kalitni tekshir.)";
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      a = localCoach(q);
    }
    s.chat.add(ChatMsg(false, a));
    if (mounted) setState(() => _busy = false);
    s.ping();
    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I,
      builder: (context, _) {
        final msgs = AppState.I.chat;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: kViolet),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Coach',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      Text(
                        AppState.I.apiKey.isEmpty
                            ? 'Oflayn rejim (Sozlamalarda AI kalit qo\'sh)'
                            : 'AI ulangan',
                        style: const TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: msgs.length + (_busy ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i >= msgs.length) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Coach yozmoqda...',
                            style: TextStyle(color: kMuted)),
                      ),
                    );
                  }
                  final m = msgs[i];
                  return Align(
                    alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: m.me ? kViolet : kSurface2,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(m.text, style: const TextStyle(height: 1.4)),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final q in const ['Tahlil', 'Reja tuz', 'Motivatsiya', 'Intizom'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text(q),
                        backgroundColor: kSurface,
                        onPressed: () => _send(q),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Coach\'dan so\'ra...',
                        filled: true,
                        fillColor: kSurface,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: kViolet),
                    onPressed: () => _send(_ctl.text),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ───────────────────────── Sozlamalar ─────────────────────────
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _key =
      TextEditingController(text: AppState.I.apiKey);

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const Text('Sozlamalar',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: kViolet,
                child: Text(
                  s.name.isEmpty ? 'E' : s.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Text(s.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('AI Coach (Anthropic API kaliti)',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text(
          "Kalit kiritilsa Coach haqiqiy AI bilan gaplashadi. Kiritilmasa — oflayn rejimda ishlaydi. "
          "Kalit faqat shu seansda saqlanadi.",
          style: TextStyle(color: kMuted, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _key,
          obscureText: true,
          onChanged: (v) {
            s.apiKey = v.trim();
            s.ping();
          },
          decoration: InputDecoration(
            hintText: 'sk-ant-...',
            prefixIcon: const Icon(Icons.key, color: kMuted),
            filled: true,
            fillColor: kSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        ListTile(
          tileColor: kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: const Icon(Icons.refresh, color: kMuted),
          title: const Text("Ma'lumotlarni boshlang'ich holatga qaytarish"),
          onTap: () {
            s.reset();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Ma'lumotlar tiklandi")),
            );
          },
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: const Icon(Icons.logout, color: kRed),
          title: const Text('Chiqish'),
          onTap: () => Navigator.of(context)
              .pushReplacement(fadeRoute(const LoginPage())),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text('ENOUGH v1.0',
              style: TextStyle(color: kMuted, fontSize: 12)),
        ),
      ],
    );
  }
}
