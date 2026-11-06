import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'names_data.dart';
import 'adhkar_data.dart';

// ---------- Themes ----------
const kThemeNames = ['کلاود', 'شین', 'نیلي', 'ارغواني', 'ټیل'];
const kThemeSeeds = [
  Color(0xFFC96442),
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF6750A4),
  Color(0xFF00796B),
];

const kDhikr = [
  'سُبْحَانَ اللَّهِ',
  'الْحَمْدُ لِلَّهِ',
  'اللَّهُ أَكْبَرُ',
  'لَا إِلَهَ إِلَّا اللَّهُ',
  'أَسْتَغْفِرُ اللَّهَ',
  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  'سُبْحَانَ اللَّهِ الْعَظِيمِ',
  'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
  'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
  'حَسْبِيَ اللَّهُ وَنِعْمَ الْوَكِيلُ',
];

// ---------- Palette ----------
class C {
  final Color bg, card, border, text, sub, accent, onAccent, soft, onSoft;
  const C({
    required this.bg,
    required this.card,
    required this.border,
    required this.text,
    required this.sub,
    required this.accent,
    required this.onAccent,
    required this.soft,
    required this.onSoft,
  });

  static const claudeLight = C(
    bg: Color(0xFFFAF9F5),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE8E6DC),
    text: Color(0xFF141413),
    sub: Color(0xFF6B6A63),
    accent: Color(0xFFC96442),
    onAccent: Colors.white,
    soft: Color(0xFFF3E3DB),
    onSoft: Color(0xFFC96442),
  );

  static const claudeDark = C(
    bg: Color(0xFF262624),
    card: Color(0xFF30302E),
    border: Color(0xFF45443F),
    text: Color(0xFFFAF9F5),
    sub: Color(0xFFB5B3A8),
    accent: Color(0xFFD97757),
    onAccent: Colors.white,
    soft: Color(0xFF3D2E28),
    onSoft: Color(0xFFD97757),
  );

  static C of(BuildContext ctx) {
    final s = Theme.of(ctx).colorScheme;
    final dark = s.brightness == Brightness.dark;
    if (store.themeIdx == 0) return dark ? claudeDark : claudeLight;
    return C(
      bg: s.surface,
      card: s.surfaceContainerLow,
      border: s.outlineVariant,
      text: s.onSurface,
      sub: s.onSurfaceVariant,
      accent: s.primary,
      onAccent: s.onPrimary,
      soft: s.primaryContainer,
      onSoft: s.onPrimaryContainer,
    );
  }
}

// ---------- Offline store ----------
class Store extends ChangeNotifier {
  SharedPreferences? _p;
  Set<int> favs = {};
  List<int> counts = List.filled(kDhikr.length, 0);
  int target = 33;
  int themeIdx = 0;
  int mode = 0; // 0 system, 1 light, 2 dark

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    favs = (_p!.getStringList('favs') ?? []).map(int.parse).toSet();
    final saved = _p!.getStringList('counts');
    if (saved != null) {
      for (var i = 0; i < counts.length && i < saved.length; i++) {
        counts[i] = int.tryParse(saved[i]) ?? 0;
      }
    }
    target = _p!.getInt('target') ?? 33;
    themeIdx = _p!.getInt('theme') ?? 0;
    if (themeIdx < 0 || themeIdx >= kThemeSeeds.length) themeIdx = 0;
    mode = _p!.getInt('mode') ?? 0;
    if (mode < 0 || mode > 2) mode = 0;
    notifyListeners();
  }

  void toggle(int i) {
    favs.contains(i) ? favs.remove(i) : favs.add(i);
    _p?.setStringList('favs', favs.map((e) => '$e').toList());
    notifyListeners();
  }

  void setCount(int idx, int v) {
    counts[idx] = v;
    _p?.setStringList('counts', counts.map((e) => '$e').toList());
    notifyListeners();
  }

  void setTarget(int v) {
    target = v;
    _p?.setInt('target', v);
    notifyListeners();
  }

  void setTheme(int v) {
    themeIdx = v;
    _p?.setInt('theme', v);
    notifyListeners();
  }

  void setMode(int v) {
    mode = v;
    _p?.setInt('mode', v);
    notifyListeners();
  }
}

final store = Store();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await store.load();
  } catch (_) {}
  runApp(const AsmaApp());
}

class AsmaApp extends StatelessWidget {
  const AsmaApp({super.key});

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    var s = ColorScheme.fromSeed(
      seedColor: kThemeSeeds[store.themeIdx],
      brightness: b,
    );
    Color bg = s.surface;
    if (store.themeIdx == 0) {
      final p = dark ? C.claudeDark : C.claudeLight;
      s = s.copyWith(primary: p.accent, surface: p.bg);
      bg = p.bg;
    }
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Naskh',
      colorScheme: s,
      scaffoldBackgroundColor: bg,
    );
  }

  @override
  Widget build(BuildContext context) {
    const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'اسماءالحسنى',
        themeMode: modes[store.mode],
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const SplashPage(),
      ),
    );
  }
}

// ---------- Helpers ----------
String nameText(List<String> n) =>
    '${n[0]} (${n[1]})\nمعنا: ${n[2]}\nفایده: ${n[3]}\n\n- اسماءالحسنى';

void copyText(BuildContext context, String t) {
  Clipboard.setData(ClipboardData(text: t));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('کاپي شو ✓'),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class FadeIn extends StatelessWidget {
  final Widget child;
  final int delay;
  const FadeIn({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 450 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, v, w) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: w),
      ),
      child: child,
    );
  }
}

void showThemeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ListenableBuilder(
      listenable: store,
      builder: (_, __) {
        final c = C.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ورځ / شپه',
                  style: TextStyle(
                      fontSize: 20,
                      color: c.text,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: 0,
                        label: Text('سیسټم'),
                        icon: Icon(Icons.brightness_auto_rounded)),
                    ButtonSegment(
                        value: 1,
                        label: Text('ورځ'),
                        icon: Icon(Icons.light_mode_rounded)),
                    ButtonSegment(
                        value: 2,
                        label: Text('شپه'),
                        icon: Icon(Icons.dark_mode_rounded)),
                  ],
                  selected: {store.mode},
                  onSelectionChanged: (s) => store.setMode(s.first),
                ),
              ),
              const SizedBox(height: 22),
              Text('د رنګ انتخاب',
                  style: TextStyle(
                      fontSize: 20,
                      color: c.text,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (var i = 0; i < kThemeSeeds.length; i++)
                    GestureDetector(
                      onTap: () => store.setTheme(i),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: kThemeSeeds[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: store.themeIdx == i
                                    ? c.text
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: store.themeIdx == i
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(kThemeNames[i],
                              style: TextStyle(color: c.sub, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

// ---------- Splash ----------
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();
  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
  );
  late final Animation<double> _ring = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => const Shell(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 700),
      ));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (_, __) {
                      final v = _ring.value;
                      return Container(
                        width: 130 + 110 * v,
                        height: 130 + 110 * v,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38 + 80 * v),
                          border: Border.all(
                            color: c.accent.withOpacity((1 - v) * 0.5),
                            width: 3,
                          ),
                        ),
                      );
                    },
                  ),
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: [
                          BoxShadow(
                            color: c.accent.withOpacity(0.35),
                            blurRadius: 36,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text('الله',
                          style: TextStyle(
                              fontSize: 54,
                              color: c.onAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Text('اسماءالحسنى',
                      style: TextStyle(
                          fontSize: 32,
                          color: c.text,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('د الله ښکلي نومونه',
                      style: TextStyle(fontSize: 16, color: c.sub)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Shell ----------
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: const [NamesTab(), AdhkarTab(), FavsTab(), TasbeehTab()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: c.card,
        indicatorColor: c.soft,
        selectedIndex: _tab,
        onDestinationSelected: (v) => setState(() => _tab = v),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined, color: c.sub),
            selectedIcon: Icon(Icons.menu_book_rounded, color: c.onSoft),
            label: 'نومونه',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined, color: c.sub),
            selectedIcon: Icon(Icons.auto_awesome_rounded, color: c.onSoft),
            label: 'اذکار',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded, color: c.sub),
            selectedIcon: Icon(Icons.favorite_rounded, color: c.onSoft),
            label: 'خوښې',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined, color: c.sub),
            selectedIcon: Icon(Icons.touch_app_rounded, color: c.onSoft),
            label: 'تسبیح',
          ),
        ],
      ),
    );
  }
}

// ---------- Name tile ----------
class NameTile extends StatelessWidget {
  final int i;
  const NameTile(this.i, {super.key});

  @override
  Widget build(BuildContext context) {
    final n = asmaNames[i];
    final c = C.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          iconColor: c.accent,
          collapsedIconColor: c.sub,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: c.soft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${i + 1}',
                style: TextStyle(
                    color: c.onSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
          title: Text(n[0],
              style: TextStyle(
                  fontSize: 24,
                  height: 1.6,
                  color: c.text,
                  fontWeight: FontWeight.bold)),
          subtitle: Text(n[1], style: TextStyle(color: c.sub, fontSize: 13)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('معنا',
                style: TextStyle(
                    color: c.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(n[2],
                style: TextStyle(fontSize: 16, height: 1.7, color: c.text)),
            const SizedBox(height: 12),
            Text('فایده',
                style: TextStyle(
                    color: c.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(n[3],
                style: TextStyle(fontSize: 16, height: 1.7, color: c.text)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => copyText(context, nameText(n)),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('کاپي'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.soft,
                      foregroundColor: c.onSoft,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Share.share(nameText(n)),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('شیر'),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.onAccent,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ListenableBuilder(
                  listenable: store,
                  builder: (_, __) => IconButton.filledTonal(
                    onPressed: () => store.toggle(i),
                    icon: Icon(store.favs.contains(i)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: c.soft,
                      foregroundColor: c.onSoft,
                      minimumSize: const Size(46, 46),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Names tab ----------
class NamesTab extends StatefulWidget {
  const NamesTab({super.key});
  @override
  State<NamesTab> createState() => _NamesTabState();
}

class _NamesTabState extends State<NamesTab> {
  final PageController _pc = PageController(viewportFraction: 0.9);
  final TextEditingController _search = TextEditingController();
  Timer? _timer;
  int _index = 0;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pc.hasClients) return;
      final next = (_index + 1) % asmaNames.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    _search.dispose();
    super.dispose();
  }

  String _norm(String s) => s
      .replaceAll(RegExp('[\u064B-\u065F\u0670]'), '')
      .replaceAll('ـ', '')
      .toLowerCase();

  bool _match(List<String> n, String q) {
    final nq = _norm(q.trim());
    return _norm(n[0]).contains(nq) ||
        n[1].toLowerCase().contains(nq) ||
        n[2].contains(q.trim()) ||
        n[3].contains(q.trim());
  }

  Widget _slide(int i) {
    final n = asmaNames[i];
    final c = C.of(context);
    return AnimatedBuilder(
      animation: _pc,
      builder: (context, child) {
        double s = 1.0;
        if (_pc.position.haveDimensions) {
          final page = _pc.page ?? _index.toDouble();
          s = (1 - ((page - i).abs() * 0.08)).clamp(0.9, 1.0);
        }
        return Transform.scale(scale: s, child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: c.accent.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: c.onAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${i + 1}',
                  style: TextStyle(color: c.onAccent, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Text(n[0],
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 44,
                    height: 1.5,
                    color: c.onAccent,
                    fontWeight: FontWeight.bold)),
            Text(n[1], style: TextStyle(fontSize: 16, color: c.onAccent)),
            const SizedBox(height: 6),
            Text(n[2],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: c.onAccent.withOpacity(0.9))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searching = _q.trim().isNotEmpty;
    final list = [
      for (var i = 0; i < asmaNames.length; i++)
        if (!searching || _match(asmaNames[i], _q)) i
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اسماءالحسنى',
                          style: TextStyle(
                              fontSize: 30,
                              color: c.text,
                              fontWeight: FontWeight.bold)),
                      Text('د الله جل جلاله ۹۹ ښکلي نومونه',
                          style: TextStyle(fontSize: 14, color: c.sub)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => store.setMode(isDark ? 1 : 2),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (w, a) =>
                        RotationTransition(turns: a, child: w),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      key: ValueKey(isDark),
                    ),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: c.soft,
                    foregroundColor: c.onSoft,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  onPressed: () => showThemeSheet(context),
                  icon: const Icon(Icons.palette_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: c.soft,
                    foregroundColor: c.onSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _q = v),
              style: TextStyle(color: c.text, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'لټون (نوم، معنا، فایده)...',
                hintStyle: TextStyle(color: c.sub),
                prefixIcon: Icon(Icons.search_rounded, color: c.sub),
                suffixIcon: searching
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: c.sub),
                        onPressed: () {
                          _search.clear();
                          setState(() => _q = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: c.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: c.accent, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        if (!searching)
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _pc,
                    itemCount: asmaNames.length,
                    onPageChanged: (v) => setState(() => _index = v),
                    itemBuilder: (_, i) => _slide(i),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 6, 40, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0, end: (_index + 1) / asmaNames.length),
                      duration: const Duration(milliseconds: 500),
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: c.border,
                        color: c.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (list.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('هیڅ نتیجه ونه موندل شوه',
                    style: TextStyle(color: c.sub, fontSize: 16)),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, k) => FadeIn(
                key: ValueKey(list[k]),
                child: NameTile(list[k]),
              ),
              childCount: list.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ---------- Adhkar tab ----------
class AdhkarTab extends StatelessWidget {
  const AdhkarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اذکار',
                  style: TextStyle(
                      fontSize: 30,
                      color: c.text,
                      fontWeight: FontWeight.bold)),
              Text('د ورځې او شپې اذکار',
                  style: TextStyle(fontSize: 14, color: c.sub)),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            for (var i = 0; i < adhkarCats.length; i++)
              FadeIn(delay: i * 80, child: _CatBox(adhkarCats[i])),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CatBox extends StatelessWidget {
  final Cat cat;
  const _CatBox(this.cat);

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdhkarPage(cat)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration:
                    BoxDecoration(color: c.soft, shape: BoxShape.circle),
                child: Icon(cat.icon, color: c.onSoft, size: 28),
              ),
              const SizedBox(height: 10),
              Text(cat.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 17,
                      color: c.text,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text('${cat.items.length} ذکرونه',
                  style: TextStyle(fontSize: 12, color: c.sub)),
            ],
          ),
        ),
      ),
    );
  }
}

class AdhkarPage extends StatelessWidget {
  final Cat cat;
  const AdhkarPage(this.cat, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(cat.title,
            style: TextStyle(
                color: c.text, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: cat.items.length,
        itemBuilder: (_, i) => FadeIn(
          delay: i * 40,
          child: DhikrCard(cat.items[i], i + 1),
        ),
      ),
    );
  }
}

class DhikrCard extends StatefulWidget {
  final Dhikr d;
  final int index;
  const DhikrCard(this.d, this.index, {super.key});
  @override
  State<DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<DhikrCard> {
  int _done = 0;

  String get _text =>
      '${widget.d.ar}\n\n${widget.d.ps}\n\n(${widget.d.n} ځله)\n- اسماءالحسنى';

  void _tap() {
    if (_done >= widget.d.n) return;
    setState(() => _done++);
    if (_done >= widget.d.n) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    final d = widget.d;
    final finished = _done >= d.n;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: finished ? c.accent : c.border, width: finished ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                    BoxDecoration(color: c.soft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('${widget.index}',
                    style: TextStyle(
                        color: c.onSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: c.soft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${d.n} ځله',
                    style: TextStyle(color: c.onSoft, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(d.ar,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  height: 2.0,
                  color: c.text,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 10),
          Text(d.ps,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.8, color: c.sub)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _tap,
                  style: FilledButton.styleFrom(
                    backgroundColor: finished ? c.soft : c.accent,
                    foregroundColor: finished ? c.onSoft : c.onAccent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          finished
                              ? Icons.check_circle_rounded
                              : Icons.touch_app_rounded,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(finished ? 'بشپړ شو' : '$_done / ${d.n}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (_done > 0)
                IconButton(
                  onPressed: () => setState(() => _done = 0),
                  icon: const Icon(Icons.refresh_rounded),
                  color: c.sub,
                ),
              IconButton(
                onPressed: () => copyText(context, _text),
                icon: const Icon(Icons.copy_rounded),
                color: c.onSoft,
              ),
              IconButton(
                onPressed: () => Share.share(_text),
                icon: const Icon(Icons.ios_share_rounded),
                color: c.onSoft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Favorites tab ----------
class FavsTab extends StatelessWidget {
  const FavsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final favs = store.favs.toList()..sort();
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text('خوښې شوي نومونه',
                  style: TextStyle(
                      fontSize: 26,
                      color: c.text,
                      fontWeight: FontWeight.bold)),
            ),
            if (favs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 56, color: c.border),
                    const SizedBox(height: 12),
                    Text(
                        'تر اوسه څه نه دي خوښ شوي.\nپه هر نوم کې د زړه تڼۍ ټک کړئ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: c.sub, fontSize: 16, height: 1.7)),
                  ],
                ),
              )
            else
              for (final i in favs)
                FadeIn(key: ValueKey('f$i'), child: NameTile(i)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ---------- Tasbeeh tab ----------
class TasbeehTab extends StatefulWidget {
  const TasbeehTab({super.key});
  @override
  State<TasbeehTab> createState() => _TasbeehTabState();
}

class _TasbeehTabState extends State<TasbeehTab> {
  int _d = 0;
  bool _pressed = false;
  static const _targets = [10, 33, 99, 100, 1000];

  void _tap() {
    final v = store.counts[_d] + 1;
    store.setCount(_d, v);
    if (v % store.target == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = C.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = store.counts[_d];
        final g = store.target;
        final inRound = t % g;
        final progress = (t > 0 && inRound == 0) ? 1.0 : inRound / g;
        final text =
            '${kDhikr[_d]}\n\n$t ځله\n- اسماءالحسنى';

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('تسبیح',
                style: TextStyle(
                    fontSize: 26,
                    color: c.text,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kDhikr.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(kDhikr[i]),
                  selected: _d == i,
                  onSelected: (_) => setState(() => _d = i),
                  selectedColor: c.soft,
                  backgroundColor: c.card,
                  side: BorderSide(color: _d == i ? c.accent : c.border),
                  labelStyle: TextStyle(
                      color: _d == i ? c.onSoft : c.text, fontSize: 15),
                  showCheckmark: false,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Center(
                key: ValueKey(_d),
                child: Text(kDhikr[_d],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 30,
                        color: c.text,
                        height: 1.7,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                onTap: _tap,
                child: AnimatedScale(
                  scale: _pressed ? 0.94 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 300),
                            builder: (_, v, __) => CircularProgressIndicator(
                              value: v,
                              strokeWidth: 10,
                              backgroundColor: c.border,
                              color: c.accent,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                        Container(
                          width: 214,
                          height: 214,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: c.accent.withOpacity(0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (w, a) =>
                                    ScaleTransition(scale: a, child: w),
                                child: Text('$t',
                                    key: ValueKey(t),
                                    style: TextStyle(
                                        fontSize: 64,
                                        color: c.onAccent,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Text('/ $g',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: c.onAccent.withOpacity(0.85))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (final x in _targets)
                  ChoiceChip(
                    label: Text('$x'),
                    selected: g == x,
                    onSelected: (_) => store.setTarget(x),
                    selectedColor: c.soft,
                    backgroundColor: c.card,
                    side: BorderSide(color: g == x ? c.accent : c.border),
                    labelStyle:
                        TextStyle(color: g == x ? c.onSoft : c.text),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Text('بشپړې دورې: ${t ~/ g}',
                  style: TextStyle(color: c.sub, fontSize: 15)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => store.setCount(_d, 0),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('بیا پیل'),
                  style: TextButton.styleFrom(foregroundColor: c.sub),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => copyText(context, text),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('کاپي'),
                  style: TextButton.styleFrom(foregroundColor: c.onSoft),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => Share.share(text),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('شیر'),
                  style: TextButton.styleFrom(foregroundColor: c.onSoft),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
