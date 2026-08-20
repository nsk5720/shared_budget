import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

abstract final class AppColors {
  static const rose = Color(0xFFE85D93);
  static const deepRose = Color(0xFFB83D70);
  static const blush = Color(0xFFFFE4EF);
  static const paleBlush = Color(0xFFFFF3F8);
  static const lavender = Color(0xFF9276D9);
  static const paleLavender = Color(0xFFF0EBFF);
  static const cream = Color(0xFFFFFAF7);
  static const surface = Color(0xFFFFFEFF);
  static const ink = Color(0xFF392D34);
  static const muted = Color(0xFF806F78);
  static const mint = Color(0xFF4BAF8C);
  static const coral = Color(0xFFE76D73);
  static const border = Color(0xFFFFDCE9);
}

LinearGradient get appGradient => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: switch (appThemeChoice.value) {
    AppThemeChoice.pink => const [Color(0xFFF178A5), Color(0xFFB18AE6)],
    AppThemeChoice.lavender => const [Color(0xFFA58AE8), Color(0xFF7B8EE8)],
    AppThemeChoice.mint => const [Color(0xFF62C9A7), Color(0xFF72A9D9)],
    AppThemeChoice.night => const [Color(0xFF6F6AB5), Color(0xFF3E527D)],
  },
);

class SoftPastelBackground extends StatelessWidget {
  const SoftPastelBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = switch (appThemeChoice.value) {
      AppThemeChoice.pink => const (
        background: [Color(0xFFFFF7FB), Color(0xFFFFFBF7)],
        firstOrb: Color(0x33F4A4C4),
        secondOrb: Color(0x279D83E2),
        thirdOrb: Color(0x22F3B994),
      ),
      AppThemeChoice.lavender => const (
        background: [Color(0xFFFAF8FF), Color(0xFFFFFAFC)],
        firstOrb: Color(0x339D83E2),
        secondOrb: Color(0x26F4A4C4),
        thirdOrb: Color(0x2279A8E5),
      ),
      AppThemeChoice.mint => const (
        background: [Color(0xFFF4FFFB), Color(0xFFFFFCF7)],
        firstOrb: Color(0x335FCBA8),
        secondOrb: Color(0x2279A8E5),
        thirdOrb: Color(0x22FFD090),
      ),
      AppThemeChoice.night => const (
        background: [Color(0xFF181622), Color(0xFF242033)],
        firstOrb: Color(0x335C57A5),
        secondOrb: Color(0x227E5A8F),
        thirdOrb: Color(0x224F8B7B),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.background,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -85,
            right: -70,
            child: _PastelOrb(size: 210, color: palette.firstOrb),
          ),
          Positioned(
            top: 245,
            left: -95,
            child: _PastelOrb(size: 190, color: palette.secondOrb),
          ),
          Positioned(
            bottom: 50,
            right: -75,
            child: _PastelOrb(size: 170, color: palette.thirdOrb),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _PastelOrb extends StatelessWidget {
  const _PastelOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

BoxDecoration softCardDecoration({Color color = AppColors.surface}) {
  final accent = appThemeChoice.value.color;
  final resolvedColor =
      appThemeChoice.value == AppThemeChoice.night && color == AppColors.surface
      ? const Color(0xFF2B2738)
      : color;
  return BoxDecoration(
    color: resolvedColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: accent.withValues(alpha: 0.2)),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.09),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const FirebaseBootstrap());
}

class FirebaseBootstrap extends StatefulWidget {
  const FirebaseBootstrap({super.key});

  @override
  State<FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<FirebaseBootstrap> {
  late Future<void> _initialization = _initializeFirebase();

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
  }

  void _retry() {
    setState(() => _initialization = _initializeFirebase());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const SharedBudgetApp();
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 54,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Firebase를 시작하지 못했습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '인터넷 연결을 확인한 뒤 다시 시도해 주세요.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('다시 연결'),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 18),
                            Text('Firebase 연결 중...'),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum AppThemeChoice { pink, lavender, mint, night }

extension AppThemeChoiceX on AppThemeChoice {
  String get label => switch (this) {
    AppThemeChoice.pink => '핑크',
    AppThemeChoice.lavender => '라벤더',
    AppThemeChoice.mint => '민트',
    AppThemeChoice.night => '나이트',
  };

  Color get color => switch (this) {
    AppThemeChoice.pink => AppColors.rose,
    AppThemeChoice.lavender => AppColors.lavender,
    AppThemeChoice.mint => AppColors.mint,
    AppThemeChoice.night => const Color(0xFF8582CF),
  };
}

final appThemeChoice = ValueNotifier(AppThemeChoice.pink);

class AppSettingsService {
  static const _channel = MethodChannel('shared_budget/settings');

  static Future<AppThemeChoice> getThemeChoice() async {
    final value = await _channel.invokeMethod<String>('getThemeChoice');
    return AppThemeChoice.values.firstWhere(
      (item) => item.name == value,
      orElse: () => AppThemeChoice.pink,
    );
  }

  static Future<void> setThemeChoice(AppThemeChoice choice) async {
    await _channel.invokeMethod<void>('setThemeChoice', {'value': choice.name});
    appThemeChoice.value = choice;
  }

  static Future<bool> hasAppPin() async =>
      await _channel.invokeMethod<bool>('hasAppPin') ?? false;

  static Future<bool> verifyAppPin(String pin) async =>
      await _channel.invokeMethod<bool>('verifyAppPin', {'pin': pin}) ?? false;

  static Future<void> setAppPin(String pin) =>
      _channel.invokeMethod<void>('setAppPin', {'pin': pin});

  static Future<void> removeAppPin() =>
      _channel.invokeMethod<void>('removeAppPin');

  static Future<bool> hasBiometric() async =>
      await _channel.invokeMethod<bool>('hasBiometric') ?? false;

  static Future<bool> getBiometricEnabled() async =>
      await _channel.invokeMethod<bool>('getBiometricEnabled') ?? false;

  static Future<void> setBiometricEnabled(bool enabled) =>
      _channel.invokeMethod<void>('setBiometricEnabled', {'enabled': enabled});

  static Future<bool> authenticateBiometric() async =>
      await _channel.invokeMethod<bool>('authenticateBiometric') ?? false;

  static Future<List<NotificationAppOption>>
  getObservedNotificationApps() async {
    final values = await _channel.invokeListMethod<dynamic>(
      'getObservedNotificationApps',
    );
    return (values ?? const [])
        .map((value) {
          final map = Map<Object?, Object?>.from(value as Map);
          return NotificationAppOption(
            packageName: map['packageName'] as String? ?? '',
            label: map['label'] as String? ?? '',
            selected: map['selected'] as bool? ?? true,
          );
        })
        .where((item) => item.packageName.isNotEmpty)
        .toList();
  }

  static Future<void> setSelectedNotificationApps(List<String> packages) =>
      _channel.invokeMethod<void>('setSelectedNotificationApps', {
        'packages': packages,
      });

  static Future<bool?> exportCsv(
    String fileName,
    String content, {
    String mimeType = 'text/csv',
  }) => _channel.invokeMethod<bool>('exportCsv', {
    'fileName': fileName,
    'content': content,
    'mimeType': mimeType,
  });

  static Future<String?> importCsv() =>
      _channel.invokeMethod<String>('importCsv');

  static Future<void> showBudgetAlert(int expense, int budget, int threshold) =>
      _channel.invokeMethod<void>('showBudgetAlert', {
        'expense': expense,
        'budget': budget,
        'threshold': threshold,
      });

  static Future<void> updateHomeWidget(int expense, int budget) =>
      _channel.invokeMethod<void>('updateHomeWidget', {
        'expense': expense,
        'budget': budget,
      });

  static Future<bool> hasCompletedOnboarding() async =>
      await _channel.invokeMethod<bool>('hasCompletedOnboarding') ?? false;

  static Future<void> completeOnboarding() =>
      _channel.invokeMethod<void>('completeOnboarding');
}

class NotificationAppOption {
  const NotificationAppOption({
    required this.packageName,
    required this.label,
    required this.selected,
  });

  final String packageName;
  final String label;
  final bool selected;
}

class SharedBudgetApp extends StatefulWidget {
  const SharedBudgetApp({super.key});

  @override
  State<SharedBudgetApp> createState() => _SharedBudgetAppState();
}

class _SharedBudgetAppState extends State<SharedBudgetApp> {
  bool _onboardingLoaded = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    try {
      final results = await Future.wait([
        AppSettingsService.getThemeChoice(),
        AppSettingsService.hasCompletedOnboarding(),
      ]);
      appThemeChoice.value = results[0] as AppThemeChoice;
      if (mounted) {
        setState(() {
          _showOnboarding = !(results[1] as bool);
          _onboardingLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _onboardingLoaded = true);
    }
  }

  Future<void> _completeOnboarding() async {
    await AppSettingsService.completeOnboarding();
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeChoice>(
      valueListenable: appThemeChoice,
      builder: (context, themeChoice, _) {
        final accent = themeChoice.color;
        final isDark = themeChoice == AppThemeChoice.night;
        final surface = isDark ? const Color(0xFF2B2738) : AppColors.surface;
        final foreground = isDark ? const Color(0xFFF8EDF5) : AppColors.ink;
        final colorScheme =
            ColorScheme.fromSeed(
              seedColor: accent,
              brightness: isDark ? Brightness.dark : Brightness.light,
              surface: surface,
            ).copyWith(
              primary: accent,
              onPrimary: Colors.white,
              primaryContainer: AppColors.blush,
              onPrimaryContainer: AppColors.deepRose,
              secondary: AppColors.lavender,
              secondaryContainer: AppColors.paleLavender,
              tertiary: AppColors.mint,
              error: AppColors.coral,
            );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '모아봄',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            scaffoldBackgroundColor: isDark
                ? const Color(0xFF181622)
                : AppColors.cream,
            textTheme: Theme.of(
              context,
            ).textTheme.apply(bodyColor: foreground, displayColor: foreground),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              foregroundColor: foreground,
              centerTitle: false,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: surface,
              surfaceTintColor: Colors.transparent,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF363044)
                  : const Color(0xFFFFF7FA),
              labelStyle: const TextStyle(color: AppColors.muted),
              hintStyle: const TextStyle(color: Color(0xFFB3A1AA)),
              prefixIconColor: AppColors.deepRose,
              suffixIconColor: AppColors.muted,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 17,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: accent, width: 1.7),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.coral),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.deepRose,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.deepRose,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: StadiumBorder(),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.blush,
              elevation: 0,
              height: 68,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.deepRose
                      : AppColors.muted,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w800
                      : FontWeight.w600,
                );
              }),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF4A3842),
              contentTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            dividerTheme: const DividerThemeData(
              color: Color(0xFFFFE3ED),
              thickness: 1,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          home: !_onboardingLoaded
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _showOnboarding
              ? WelcomeOnboardingPage(onComplete: _completeOnboarding)
              : const AuthGate(),
        );
      },
    );
  }
}

class WelcomeOnboardingPage extends StatefulWidget {
  const WelcomeOnboardingPage({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<WelcomeOnboardingPage> createState() => _WelcomeOnboardingPageState();
}

class _WelcomeOnboardingPageState extends State<WelcomeOnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _slides = [
    (
      icon: Icons.favorite_rounded,
      title: '둘이서도, 혼자서도 편안하게',
      body: '개인 가계부를 쓰다가 원하는 사람과 연결해 같은 내역을 함께 볼 수 있어요.',
    ),
    (
      icon: Icons.auto_awesome_rounded,
      title: '결제 알림을 똑똑하게 정리해요',
      body: 'SMS와 은행·카드 Push에서 날짜, 사용처, 금액과 분류를 찾아 저장 전에 보여드려요.',
    ),
    (
      icon: Icons.spa_rounded,
      title: '예산도 부드럽고 한눈에',
      body: '하루 권장 지출, 월말 예상 금액, 저축 목표까지 깔끔한 대시보드에서 확인하세요.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _slides.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftPastelBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: const Text('건너뛰기'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              gradient: appGradient,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.22),
                                  blurRadius: 30,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Icon(
                              slide.icon,
                              color: Colors.white,
                              size: 52,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _page ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _finishing ? null : _next,
                    child: Text(_page == _slides.length - 1 ? '시작하기' : '다음'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }
        return BudgetShell(user: user);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isSignUp) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final user = credential.user!;
        final inviteCode = user.uid.substring(0, 8).toUpperCase();
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'inviteCode': inviteCode,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _authErrorMessage(error.code));
      }
    } on FirebaseException {
      if (mounted) {
        setState(() => _errorMessage = 'Firebase 설정을 확인해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showFindId() {
    final enteredEmail = _emailController.text.trim();
    final hasValidEmail = RegExp(
      r'^[^@]+@[^@]+\.[^@]+$',
    ).hasMatch(enteredEmail);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('아이디 찾기'),
        content: Text(
          '모아봄의 아이디는 회원가입할 때 사용한 이메일 주소입니다.\n\n'
          '${hasValidEmail ? '현재 입력한 이메일: $enteredEmail\n\n' : ''}'
          '휴대폰의 설정 → 계정 및 백업 → 계정 관리에서 본인이 사용하는 '
          'Google 이메일을 확인해 보세요. 개인정보 보호를 위해 이름이나 '
          '전화번호만으로 다른 사람의 이메일은 검색하지 않습니다.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasswordReset() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    String? dialogError;
    var isSending = false;

    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('비밀번호 재설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '가입한 이메일을 입력하면 비밀번호를 다시 설정할 수 있는 '
                '메일을 보내드립니다.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: resetEmailController,
                enabled: !isSending,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '가입 이메일',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 12),
                Text(
                  dialogError!,
                  style: const TextStyle(color: Color(0xFFEF4444)),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSending
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
                        setDialogState(() => dialogError = '올바른 이메일을 입력해 주세요.');
                        return;
                      }

                      setDialogState(() {
                        isSending = true;
                        dialogError = null;
                      });
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: email,
                        );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(true);
                        }
                      } on FirebaseAuthException catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            isSending = false;
                            dialogError = _passwordResetErrorMessage(
                              error.code,
                            );
                          });
                        }
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('재설정 메일 보내기'),
            ),
          ],
        ),
      ),
    );
    disposeControllerAfterDialog(resetEmailController);

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재설정 메일을 보냈습니다. 메일함과 스팸함을 확인해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftPastelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: softCardDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              gradient: appGradient,
                              borderRadius: BorderRadius.circular(29),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x35E85D93),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 38,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paleLavender,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              '소중한 하루를 함께 기록해요 ✿',
                              style: TextStyle(
                                color: AppColors.lavender,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isSignUp ? '모아봄 시작하기' : '다시 만나서 반가워요',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp
                              ? '계정을 만들고 가계부를 안전하게 저장하세요.'
                              : '로그인하고 저장된 가계부를 불러오세요.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '이메일',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null ||
                                !RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+$',
                                ).hasMatch(value)) {
                              return '올바른 이메일을 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: '비밀번호',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return '비밀번호는 6자 이상 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                        if (!_isSignUp) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _isLoading ? null : _showFindId,
                                child: const Text('아이디 찾기'),
                              ),
                              const Text(
                                '|',
                                style: TextStyle(color: Color(0xFFD1D5DB)),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _showPasswordReset,
                                child: const Text('비밀번호 재설정'),
                              ),
                            ],
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isSignUp ? '회원가입' : '로그인',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _errorMessage = null;
                                  });
                                },
                          child: Text(
                            _isSignUp ? '이미 계정이 있나요? 로그인' : '처음이신가요? 회원가입',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _passwordResetErrorMessage(String code) {
  return switch (code) {
    'invalid-email' => '올바른 이메일을 입력해 주세요.',
    'too-many-requests' => '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.',
    'network-request-failed' => '인터넷 연결을 확인해 주세요.',
    _ => '메일을 보내지 못했습니다. 잠시 후 다시 시도해 주세요.',
  };
}

String _authErrorMessage(String code) {
  return switch (code) {
    'email-already-in-use' => '이미 가입된 이메일입니다.',
    'invalid-email' => '올바른 이메일을 입력해 주세요.',
    'weak-password' => '조금 더 안전한 비밀번호를 사용해 주세요.',
    'invalid-credential' => '이메일 또는 비밀번호가 맞지 않습니다.',
    'user-not-found' => '가입되지 않은 이메일입니다.',
    'wrong-password' => '비밀번호가 맞지 않습니다.',
    'network-request-failed' => '인터넷 연결을 확인해 주세요.',
    _ => '로그인 중 문제가 발생했습니다. 다시 시도해 주세요.',
  };
}

enum TransactionType { expense, income }

enum AddTransactionOutcome { saved, dismissed, discarded }

String merchantRuleKey(String title, TransactionType type) {
  final normalized = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^0-9a-z가-힣]'), '')
      .trim();
  return '${type.name}:$normalized';
}

bool isLearnableMerchantTitle(String title) {
  final value = title.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  return value.length >= 2 &&
      !const {'카드결제', '결제', '입금', '출금', '송금', '이체', '완료', '알림'}.contains(value);
}

const defaultExpenseCategories = [
  '식비',
  '카페',
  '교통',
  '쇼핑',
  '생활',
  '의료',
  '환불',
  '기타',
];

const defaultIncomeCategories = ['급여', '용돈', '부수입', '기타'];

const defaultCategoryIconKeys = <String, String>{
  '식비': 'restaurant',
  '카페': 'cafe',
  '교통': 'bus',
  '쇼핑': 'shopping',
  '생활': 'home',
  '의료': 'medical',
  '환불': 'refund',
  '기타': 'more',
  '급여': 'bank',
  '용돈': 'savings',
  '부수입': 'trending',
};

const categoryIconChoices = <String, IconData>{
  'restaurant': Icons.restaurant_rounded,
  'cafe': Icons.local_cafe_rounded,
  'bus': Icons.directions_bus_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'home': Icons.home_rounded,
  'medical': Icons.local_hospital_rounded,
  'bank': Icons.account_balance_rounded,
  'savings': Icons.savings_rounded,
  'trending': Icons.trending_up_rounded,
  'pet': Icons.pets_rounded,
  'school': Icons.school_rounded,
  'flight': Icons.flight_rounded,
  'gift': Icons.card_giftcard_rounded,
  'fitness': Icons.fitness_center_rounded,
  'phone': Icons.phone_android_rounded,
  'car': Icons.directions_car_rounded,
  'game': Icons.sports_esports_rounded,
  'refund': Icons.currency_exchange_rounded,
  'more': Icons.more_horiz_rounded,
};

final Map<String, String> _runtimeCategoryIconKeys = {
  ...defaultCategoryIconKeys,
};

class BudgetTransaction {
  BudgetTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.memo = '',
    this.deletedAt,
    this.createdBy = '',
    this.sourceApp = '',
    this.installmentMonths,
    this.recognitionConfidence,
    this.sourceMessageId = '',
    this.isRefund = false,
  });

  final String id;
  final String title;
  final String category;
  final int amount;
  final TransactionType type;
  final DateTime date;
  final String memo;
  final DateTime? deletedAt;
  final String createdBy;
  final String sourceApp;
  final int? installmentMonths;
  final double? recognitionConfidence;
  final String sourceMessageId;
  final bool isRefund;

  Map<String, Object?> toFirestore(
    String userId, {
    bool includeCreatedAt = true,
    bool includeCreatedBy = true,
  }) {
    final data = <String, Object?>{
      'title': title,
      'category': category,
      'amount': amount,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'memo': memo,
      'isRefund': isRefund,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (sourceApp.isNotEmpty) data['sourceApp'] = sourceApp;
    if (installmentMonths != null) {
      data['installmentMonths'] = installmentMonths;
    }
    if (recognitionConfidence != null) {
      data['recognitionConfidence'] = recognitionConfidence;
    }
    if (sourceMessageId.isNotEmpty) {
      data['sourceMessageId'] = sourceMessageId;
    }
    if (includeCreatedBy) {
      data['createdBy'] = userId;
    }
    if (includeCreatedAt) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    return data;
  }
}

class LedgerOption {
  const LedgerOption({
    required this.id,
    required this.name,
    required this.memberEmails,
  });

  final String id;
  final String name;
  final List<String> memberEmails;

  bool get isShared => id.startsWith('shared_');
}

enum RepeatCycle { monthly, weekly, yearly }

extension RepeatCycleX on RepeatCycle {
  String get label => switch (this) {
    RepeatCycle.monthly => '매월',
    RepeatCycle.weekly => '매주',
    RepeatCycle.yearly => '매년',
  };
}

class RecurringTransactionRule {
  const RecurringTransactionRule({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.day,
    this.memo = '',
    this.enabled = true,
    this.cycle = RepeatCycle.monthly,
    this.month = 1,
    this.weekday = DateTime.monday,
    this.endDate,
    this.confirmBeforeAdding = false,
    this.variableAmount = false,
  });

  final String id;
  final String title;
  final String category;
  final int amount;
  final TransactionType type;
  final int day;
  final String memo;
  final bool enabled;
  final RepeatCycle cycle;
  final int month;
  final int weekday;
  final DateTime? endDate;
  final bool confirmBeforeAdding;
  final bool variableAmount;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'category': category,
    'amount': amount,
    'type': type.name,
    'day': day,
    'memo': memo,
    'enabled': enabled,
    'cycle': cycle.name,
    'month': month,
    'weekday': weekday,
    'endDate': endDate?.toIso8601String(),
    'confirmBeforeAdding': confirmBeforeAdding,
    'variableAmount': variableAmount,
  };

  static RecurringTransactionRule? fromMap(Object? value) {
    if (value is! Map) return null;
    final map = Map<Object?, Object?>.from(value);
    final title = map['title'] as String? ?? '';
    final amount = (map['amount'] as num?)?.toInt() ?? 0;
    final day = (map['day'] as num?)?.toInt() ?? 1;
    if (title.isEmpty || amount <= 0) return null;
    return RecurringTransactionRule(
      id: map['id'] as String? ?? title,
      title: title,
      category: map['category'] as String? ?? '기타',
      amount: amount,
      type: map['type'] == TransactionType.income.name
          ? TransactionType.income
          : TransactionType.expense,
      day: day.clamp(1, 31),
      memo: map['memo'] as String? ?? '',
      enabled: map['enabled'] as bool? ?? true,
      cycle: RepeatCycle.values.firstWhere(
        (cycle) => cycle.name == map['cycle'],
        orElse: () => RepeatCycle.monthly,
      ),
      month: ((map['month'] as num?)?.toInt() ?? 1).clamp(1, 12),
      weekday: ((map['weekday'] as num?)?.toInt() ?? DateTime.monday).clamp(
        DateTime.monday,
        DateTime.sunday,
      ),
      endDate: DateTime.tryParse(map['endDate'] as String? ?? ''),
      confirmBeforeAdding: map['confirmBeforeAdding'] as bool? ?? false,
      variableAmount: map['variableAmount'] as bool? ?? false,
    );
  }
}

class SmsTransactionDraft {
  const SmsTransactionDraft({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.rawMessage,
    this.type = TransactionType.expense,
    this.sourceApp = '',
    this.installmentMonths,
    this.confidence = 1,
    this.sourceMessageId = '',
    this.isRefund = false,
  });

  final String title;
  final int amount;
  final String category;
  final DateTime date;
  final String rawMessage;
  final TransactionType type;
  final String sourceApp;
  final int? installmentMonths;
  final double confidence;
  final String sourceMessageId;
  final bool isRefund;
}

class PendingPayment {
  const PendingPayment({required this.rawMessage, required this.receivedAt});

  final String rawMessage;
  final DateTime receivedAt;

  String get source => rawMessage.split('\n').first.trim();
}

class PendingPaymentsAction {
  const PendingPaymentsAction.review(this.payment) : rawMessages = const [];
  const PendingPaymentsAction.remove(this.rawMessages) : payment = null;

  final PendingPayment? payment;
  final List<String> rawMessages;
}

class _ParsedAmount {
  const _ParsedAmount(this.value, this.match);

  final int value;
  final RegExpMatch match;
}

class SmsTransactionParser {
  static final _amountPattern = RegExp(
    r'(?:₩|KRW\s*)\s*([\d,]+)|([\d,]+)\s*(?:원|KRW)',
    caseSensitive: false,
  );
  static final _transactionKeywords = RegExp(
    r'승인|결제|사용|출금|입금|송금|이체|취소|환불|환급|입금완료|출금완료',
    caseSensitive: false,
  );
  static final _incomeKeywords = RegExp(
    r'입금|급여|월급|이자|배당|송금\s*받|받은\s*송금|환불|환급|취소|캐시백',
    caseSensitive: false,
  );

  static SmsTransactionDraft? parse(String rawValue, {DateTime? receivedAt}) {
    final rawMessage = rawValue.trim();
    if (rawMessage.isEmpty) {
      return null;
    }
    final message = _contentWithoutSource(rawMessage);
    final parsedAmount = _findTransactionAmount(message);
    if (parsedAmount == null) {
      return null;
    }

    final isRefund = RegExp(r'취소|환불|환급|승인취소').hasMatch(message);
    final type = isRefund
        ? TransactionType.expense
        : _incomeKeywords.hasMatch(message)
        ? TransactionType.income
        : TransactionType.expense;
    final title = _findTitle(message, parsedAmount.match, type);
    final sourceApp = _findSource(rawMessage);
    final installment = RegExp(r'(\d{1,2})\s*개월\s*할부').firstMatch(message);
    final date = _findDate(message, receivedAt ?? DateTime.now());
    var confidence = 0.45;
    if (!const {'입금', '카드 결제'}.contains(title)) confidence += 0.25;
    if (_containsDate(message)) confidence += 0.15;
    if (sourceApp.isNotEmpty) confidence += 0.1;
    if (_transactionKeywords.hasMatch(message)) confidence += 0.05;
    return SmsTransactionDraft(
      title: title,
      amount: parsedAmount.value,
      category: isRefund ? '환불' : _categoryFor(title, message, type),
      date: date,
      rawMessage: rawMessage,
      type: type,
      sourceApp: sourceApp,
      installmentMonths: int.tryParse(installment?.group(1) ?? ''),
      confidence: confidence.clamp(0, 1),
      sourceMessageId: stableMessageId(rawMessage),
      isRefund: isRefund,
    );
  }

  static String _findSource(String rawMessage) {
    final lines = rawMessage.split('\n');
    if (lines.length < 2) return '';
    final first = lines.first.trim();
    return first.length <= 40 &&
            !_amountPattern.hasMatch(first) &&
            !_transactionKeywords.hasMatch(first)
        ? first
        : '';
  }

  static bool _containsDate(String message) {
    return RegExp(
      r'(?:\d{2,4}[./-])?\d{1,2}[./-]\d{1,2}|\d{1,2}월\s*\d{1,2}일',
    ).hasMatch(message);
  }

  static String _contentWithoutSource(String rawMessage) {
    final lines = rawMessage.split('\n');
    if (lines.length < 2) {
      return rawMessage;
    }
    final firstLine = lines.first.trim();
    final remaining = lines.skip(1).join('\n').trim();
    final firstLooksLikeSource =
        !_amountPattern.hasMatch(firstLine) &&
        !_transactionKeywords.hasMatch(firstLine) &&
        firstLine.length <= 40;
    return firstLooksLikeSource ? remaining : rawMessage;
  }

  static _ParsedAmount? _findTransactionAmount(String message) {
    _ParsedAmount? selected;
    var selectedScore = -1000;
    for (final match in _amountPattern.allMatches(message)) {
      final amountText = match.group(1) ?? match.group(2);
      final amount = int.tryParse(amountText!.replaceAll(',', ''));
      if (amount == null || amount <= 0) {
        continue;
      }
      final start = (match.start - 28).clamp(0, message.length);
      final end = (match.end + 28).clamp(0, message.length);
      final nearby = message.substring(start, end);
      var score = _transactionKeywords.hasMatch(nearby) ? 5 : 0;
      if (RegExp(r'잔액|누적|한도|예정|총액').hasMatch(nearby)) {
        score -= 4;
      }
      if (score > selectedScore) {
        selected = _ParsedAmount(amount, match);
        selectedScore = score;
      }
    }
    return selected;
  }

  static DateTime _findDate(String message, DateTime receivedAt) {
    final fullDate = RegExp(
      r'(\d{4}|\d{2})\s*(?:년|[./-])\s*(\d{1,2})\s*(?:월|[./-])\s*'
      r'(\d{1,2})\s*(?:일)?(?:\s*(?:\([월화수목금토일]\)|[월화수목금토일]요일)?\s*'
      r'(오전|오후|AM|PM)?\s*(\d{1,2})(?::|시)\s*(\d{2})(?:분)?)?',
      caseSensitive: false,
    ).firstMatch(message);
    if (fullDate != null) {
      final rawYear = int.parse(fullDate.group(1)!);
      return _safeDate(
        rawYear < 100 ? 2000 + rawYear : rawYear,
        int.parse(fullDate.group(2)!),
        int.parse(fullDate.group(3)!),
        _parseHour(fullDate.group(5), fullDate.group(4)),
        int.tryParse(fullDate.group(6) ?? '') ?? 0,
        receivedAt,
      );
    }
    final shortDate = RegExp(
      r'(\d{1,2})[./-](\d{1,2})(?:\s*(?:\([월화수목금토일]\)|[월화수목금토일]요일)?\s*'
      r'(오전|오후|AM|PM)?\s*(\d{1,2})(?::|시)\s*(\d{2})(?:분)?)?',
      caseSensitive: false,
    ).firstMatch(message);
    final koreanDate = RegExp(
      r'(\d{1,2})월\s*(\d{1,2})일(?:\s*(?:\([월화수목금토일]\)|[월화수목금토일]요일)?\s*'
      r'(오전|오후|AM|PM)?\s*(\d{1,2})(?::|시)\s*(\d{2})(?:분)?)?',
      caseSensitive: false,
    ).firstMatch(message);
    final match = shortDate ?? koreanDate;
    if (match == null) {
      return receivedAt;
    }
    final month = int.parse(match.group(1)!);
    final year = month > receivedAt.month + 1
        ? receivedAt.year - 1
        : receivedAt.year;
    return _safeDate(
      year,
      month,
      int.parse(match.group(2)!),
      _parseHour(match.group(4), match.group(3)),
      int.tryParse(match.group(5) ?? '') ?? 0,
      receivedAt,
    );
  }

  static int _parseHour(String? value, String? meridiem) {
    var hour = int.tryParse(value ?? '') ?? 0;
    final marker = meridiem?.toUpperCase();
    if ((marker == '오후' || marker == 'PM') && hour < 12) {
      hour += 12;
    } else if ((marker == '오전' || marker == 'AM') && hour == 12) {
      hour = 0;
    }
    return hour;
  }

  static DateTime _safeDate(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    DateTime fallback,
  ) {
    if (month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31 ||
        hour > 23 ||
        minute > 59) {
      return fallback;
    }
    final value = DateTime(year, month, day, hour, minute);
    return value.month == month && value.day == day ? value : fallback;
  }

  static String _findTitle(
    String message,
    RegExpMatch amountMatch,
    TransactionType type,
  ) {
    final counterpart = RegExp(
      r'([0-9A-Za-z가-힣()._-]{2,}?)\s*님?(?:에게|으로부터|에서)',
    ).firstMatch(message);
    if (counterpart != null) {
      return counterpart.group(1)!;
    }

    final amountLine =
        message.substring(0, amountMatch.start).split('\n').length - 1;
    final lines = message.split('\n');
    final orderedLines = <String>[
      if (amountLine >= 0 && amountLine < lines.length) lines[amountLine],
      if (amountLine + 1 < lines.length) lines[amountLine + 1],
      if (amountLine > 0) lines[amountLine - 1],
    ];
    for (final line in orderedLines) {
      final cleaned = _cleanTitleCandidate(line);
      if (_isUsefulTitle(cleaned)) {
        return cleaned;
      }
    }
    return type == TransactionType.income ? '입금' : '카드 결제';
  }

  static String _cleanTitleCandidate(String value) {
    return value
        .replaceAll(RegExp(r'\[[^\]]+\]'), ' ')
        .replaceAll(_amountPattern, ' ')
        .replaceAll(RegExp(r'20\d{2}[./-]\d{1,2}[./-]\d{1,2}'), ' ')
        .replaceAll(RegExp(r'\d{1,2}[./-]\d{1,2}'), ' ')
        .replaceAll(RegExp(r'\d{1,2}:\d{2}'), ' ')
        .replaceAll(RegExp(r'\d{2,4}[-*]\d{2,4}[-*\d]+'), ' ')
        .replaceAll(RegExp(r'\S*\*+\S*\s*님'), ' ')
        .replaceAll(
          RegExp(
            r'정상\s*처리\s*완료|처리\s*완료|승인\s*완료|결제\s*완료|사용\s*완료|출금\s*완료|입금\s*완료|송금\s*완료|이체\s*완료|취소\s*완료|환불\s*완료|환급\s*완료|승인|결제|사용|출금|입금|송금|이체|취소|환불|환급|일시불|\d+개월\s*할부|체크카드|신용카드|누적|잔액|한도|처리|완료',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'(?:KB국민|신한|우리|하나|삼성|현대|롯데|NH농협|BC)\s*카드'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isUsefulTitle(String value) {
    if (value.length < 2 || value.length > 35) {
      return false;
    }
    return !RegExp(
      r'^알림$|^카드$|^은행$|^결제$|^입금$|^출금$|^송금$|^이체$|^처리$|^완료$|^정상$|^정상\s*처리$|^정상\s*처리\s*완료$',
    ).hasMatch(value);
  }

  static String _categoryFor(
    String title,
    String message,
    TransactionType type,
  ) {
    final value = '$title $message'.toLowerCase();
    if (type == TransactionType.income) {
      if (RegExp(r'급여|월급|상여|보너스').hasMatch(value)) {
        return '급여';
      }
      if (RegExp(r'용돈|생일|축하').hasMatch(value)) {
        return '용돈';
      }
      if (RegExp(r'이자|배당|캐시백|환급').hasMatch(value)) {
        return '부수입';
      }
      return '기타';
    }
    if (RegExp(r'스타벅스|투썸|이디야|메가\s*커피|컴포즈|빽다방|카페|커피').hasMatch(value)) {
      return '카페';
    }
    if (RegExp(r'버스|택시|지하철|카카오\s*t|코레일|철도|주유|충전소|하이패스|주차').hasMatch(value)) {
      return '교통';
    }
    if (RegExp(r'병원|의원|약국|치과|한의원|건강검진').hasMatch(value)) {
      return '의료';
    }
    if (RegExp(r'쿠팡|네이버\s*페이|올리브영|백화점|무신사|쇼핑|아웃렛').hasMatch(value)) {
      return '쇼핑';
    }
    if (RegExp(r'전기|수도|가스|통신|관리비|보험|월세|렌탈|세탁').hasMatch(value)) {
      return '생활';
    }
    if (RegExp(
      r'마트|식당|배달|배민|쿠팡이츠|요기요|편의점|gs25|cu|uc|세븐일레븐|맥도날드|버거|치킨|피자',
    ).hasMatch(value)) {
      return '식비';
    }
    return '기타';
  }
}

class SmsPlatformService {
  static const _channel = MethodChannel('shared_budget/sms');

  static void setNotificationTapHandler(Future<void> Function() handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'smsNotificationTapped') {
        await handler();
      }
    });
  }

  static Future<void> requestPermission() async {
    await _channel.invokeMethod<bool>('requestSmsPermission');
  }

  static Future<bool> hasDisclosureConsent() async {
    return await _channel.invokeMethod<bool>('hasSmsDisclosureConsent') ??
        false;
  }

  static Future<void> saveDisclosureConsent() async {
    await _channel.invokeMethod<void>('saveSmsDisclosureConsent');
  }

  static Future<bool> hasNotificationAccess() async {
    return await _channel.invokeMethod<bool>('hasNotificationAccess') ?? false;
  }

  static Future<void> openNotificationAccessSettings() async {
    await _channel.invokeMethod<void>('openNotificationAccessSettings');
  }

  static Future<PendingPayment?> getPendingSms() async {
    final value = await _channel.invokeMapMethod<String, dynamic>(
      'getPendingSms',
    );
    if (value == null) {
      return null;
    }
    final rawMessage = value['rawMessage'] as String?;
    final receivedAtMillis = value['receivedAt'] as int?;
    if (rawMessage == null || rawMessage.trim().isEmpty) {
      return null;
    }
    return PendingPayment(
      rawMessage: rawMessage,
      receivedAt: receivedAtMillis == null || receivedAtMillis <= 0
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(receivedAtMillis),
    );
  }

  static Future<int> getPendingPaymentCount() async {
    return await _channel.invokeMethod<int>('getPendingPaymentCount') ?? 0;
  }

  static Future<List<PendingPayment>> getPendingPayments() async {
    final values = await _channel.invokeListMethod<dynamic>(
      'getPendingPayments',
    );
    return (values ?? const [])
        .map((value) {
          final map = Map<Object?, Object?>.from(value as Map);
          final receivedAtMillis = map['receivedAt'] as int?;
          return PendingPayment(
            rawMessage: map['rawMessage'] as String? ?? '',
            receivedAt: receivedAtMillis == null || receivedAtMillis <= 0
                ? DateTime.now()
                : DateTime.fromMillisecondsSinceEpoch(receivedAtMillis),
          );
        })
        .where((item) => item.rawMessage.trim().isNotEmpty)
        .toList();
  }

  static Future<int> removePendingPayments(List<String> rawMessages) async {
    return await _channel.invokeMethod<int>('removePendingPayments', {
          'rawMessages': rawMessages,
        }) ??
        0;
  }

  static Future<int> clearPendingSms() async {
    return await _channel.invokeMethod<int>('clearPendingSms') ?? 0;
  }
}

class BudgetShell extends StatefulWidget {
  const BudgetShell({super.key, required this.user});

  final User user;

  @override
  State<BudgetShell> createState() => _BudgetShellState();
}

class _BudgetShellState extends State<BudgetShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _checkingSms = false;
  bool _loadingTransactions = true;
  bool _connectingFirestore = false;
  int _pendingPaymentCount = 0;
  String? _connectionError;
  bool _isFromCache = false;
  bool _hasPendingWrites = false;
  String? _lastPresentedSms;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _transactionSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ledgerSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _categorySubscription;

  final List<BudgetTransaction> _transactions = [];
  final List<BudgetTransaction> _deletedTransactions = [];
  final Set<String> _knownTransactionIds = {};
  bool _transactionStreamInitialized = false;
  List<String> _expenseCategories = [...defaultExpenseCategories];
  List<String> _incomeCategories = [...defaultIncomeCategories];
  Map<String, String> _categoryIconKeys = {...defaultCategoryIconKeys};
  Map<String, String> _merchantCategoryRules = {};
  Map<String, String> _merchantTitleRules = {};
  int _monthlyBudget = 0;
  Map<String, int> _categoryBudgets = {};
  int _monthlySavingsGoal = 0;
  List<RecurringTransactionRule> _recurringRules = [];
  String? _recurringGenerationKey;
  String? _budgetAlertKey;
  bool _lockLoaded = false;
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _appUnlocked = true;
  DateTime? _backgroundedAt;
  String _ledgerId = '';
  String _ledgerName = '내 가계부';
  List<String> _ledgerMemberEmails = [];
  List<String> _ledgerMemberIds = [];
  String _ledgerColorKey = 'pink';
  List<LedgerOption> _availableLedgers = [];
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> _ledgerDocuments =
      {};
  String? _preferredLedgerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppLock();
    _connectFirestore();
    SmsPlatformService.setNotificationTapHandler(() async {
      _lastPresentedSms = null;
      await _checkPendingSms();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _prepareSmsAccess();
        await _refreshPendingPaymentCount();
        await _checkPendingSms();
      } on MissingPluginException {
        // iOS와 위젯 테스트에서는 Android 문자 채널을 사용하지 않습니다.
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPendingPaymentCount();
      final backgroundedAt = _backgroundedAt;
      if (_appLockEnabled &&
          backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) >
              const Duration(seconds: 20)) {
        setState(() => _appUnlocked = false);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
    }
  }

  Future<void> _loadAppLock() async {
    try {
      final values = await Future.wait([
        AppSettingsService.hasAppPin(),
        AppSettingsService.getBiometricEnabled(),
      ]);
      final enabled = values[0];
      if (mounted) {
        setState(() {
          _appLockEnabled = enabled;
          _biometricEnabled = values[1];
          _appUnlocked = !enabled;
          _lockLoaded = true;
        });
      }
    } on MissingPluginException {
      if (mounted) setState(() => _lockLoaded = true);
    }
  }

  Future<void> _prepareSmsAccess() async {
    final alreadyConsented = await SmsPlatformService.hasDisclosureConsent();
    if (!alreadyConsented) {
      if (!mounted) {
        return;
      }
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('결제 문자·Push 자동등록 안내'),
          content: const SingleChildScrollView(
            child: Text(
              '모아봄은 새로 수신되는 결제 SMS 문자와 은행·카드 앱이 '
              '표시하는 결제 Push 알림을 감지합니다. 기존 문자함 전체는 '
              '읽지 않습니다.\n\n'
              '문자 수신 권한은 새 결제 문자를 자동 입력하는 데 사용합니다. '
              '알림 접근을 허용하면 Android 기능상 다른 앱의 알림을 볼 수 '
              '있지만, 이 앱은 금액과 결제 관련 단어가 함께 있는 알림만 '
              '대기 목록에 넣고 나머지는 저장하지 않습니다.\n\n'
              '문자와 Push에서 사용처, 금액, 날짜를 자동으로 입력하고 원문을 메모에 '
              '표시합니다. 사용자가 저장하기를 누른 경우에만 해당 '
              '내용이 Firebase에 저장되며, 함께쓰기 중이라면 연결된 상대방도 '
              '볼 수 있습니다.\n\n'
              '동의하지 않아도 직접 내역을 입력해 가계부를 사용할 수 '
              '있습니다.',
              style: TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('사용 안 함'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('동의하고 계속'),
            ),
          ],
        ),
      );
      if (accepted != true) {
        return;
      }
      await SmsPlatformService.saveDisclosureConsent();
    }

    await SmsPlatformService.requestPermission();

    final hasNotificationAccess =
        await SmsPlatformService.hasNotificationAccess();
    if (!hasNotificationAccess && mounted) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('결제 Push 알림 연결'),
          content: const Text(
            '다음 화면에서 ‘모아봄 결제 알림 읽기’를 찾아 켜 주세요. '
            '그래야 은행·카드 앱의 결제 알림을 자동으로 가져올 수 있습니다.',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('나중에'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('설정 열기'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await SmsPlatformService.openNotificationAccessSettings();
      }
    }
  }

  Future<void> _connectFirestore() async {
    if (_connectingFirestore) {
      return;
    }
    _connectingFirestore = true;

    await _transactionSubscription?.cancel();
    await _ledgerSubscription?.cancel();
    await _categorySubscription?.cancel();
    _transactionSubscription = null;
    _ledgerSubscription = null;
    _categorySubscription = null;

    if (mounted) {
      setState(() {
        _loadingTransactions = true;
        _connectionError = null;
      });
    }
    final database = FirebaseFirestore.instance;
    final user = widget.user;
    final inviteCode = user.uid.substring(0, 8).toUpperCase();
    final personalLedgerId = 'personal_${user.uid}';
    final ledgerReference = database
        .collection('ledgers')
        .doc(personalLedgerId);

    try {
      // 실제 휴대폰에 저장된 캐시가 있으면 서버 응답 전에 먼저 화면을 엽니다.
      try {
        final cachedLedger = await ledgerReference.get(
          const GetOptions(source: Source.cache),
        );
        if (cachedLedger.exists) {
          _activateLedger(cachedLedger);
        }
      } on FirebaseException {
        // 첫 설치처럼 캐시가 없는 경우에는 서버에서 가계부를 확인합니다.
      }

      var ledgerSnapshot = await ledgerReference
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      if (!ledgerSnapshot.exists) {
        await ledgerReference
            .set({
              'name': '내 가계부',
              'memberIds': [user.uid],
              'memberEmails': [user.email],
              'createdBy': user.uid,
              'expenseCategories': defaultExpenseCategories,
              'incomeCategories': defaultIncomeCategories,
              'categoryIcons': defaultCategoryIconKeys,
              'updatedAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 15));
        ledgerSnapshot = await ledgerReference
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));
      }

      if (!ledgerSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Personal ledger was not created.',
        );
      }

      // 거래 읽기를 먼저 시작하고, 계정 메타데이터 저장은 뒤에서 처리합니다.
      _activateLedger(ledgerSnapshot);
      unawaited(_loadPreferredLedger());
      unawaited(
        _syncAccountMetadata(
          database: database,
          user: user,
          inviteCode: inviteCode,
          ledgerReference: ledgerReference,
        ),
      );

      _ledgerSubscription = database
          .collection('ledgers')
          .where('memberIds', arrayContains: user.uid)
          .snapshots()
          .listen(
            _selectActiveLedger,
            onError: (Object error) {
              _setConnectionError(error);
            },
          );
    } on TimeoutException {
      _setConnectionError('Firebase 연결 시간이 초과되었습니다. 인터넷을 확인하고 다시 시도해 주세요.');
    } on FirebaseException catch (error) {
      debugPrint('Firestore connection failed: ${error.code} ${error.message}');
      _setConnectionError(error);
    } catch (error) {
      debugPrint('Unexpected Firestore connection error: $error');
      _setConnectionError('Firebase 연결 중 문제가 발생했습니다. 다시 시도해 주세요.');
    } finally {
      _connectingFirestore = false;
    }
  }

  Future<void> _loadPreferredLedger() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      final preferredId = snapshot.data()?['activeLedgerId'] as String?;
      if (preferredId == null || preferredId.isEmpty) {
        return;
      }
      _preferredLedgerId = preferredId;
      final document = _ledgerDocuments[preferredId];
      if (document != null && mounted) {
        _activateLedger(document);
      }
    } catch (error) {
      debugPrint('Preferred ledger load failed: $error');
    }
  }

  Future<void> _syncAccountMetadata({
    required FirebaseFirestore database,
    required User user,
    required String inviteCode,
    required DocumentReference<Map<String, dynamic>> ledgerReference,
  }) async {
    try {
      final batch = database.batch();
      batch.set(database.collection('users').doc(user.uid), {
        'email': user.email,
        'inviteCode': inviteCode,
        'appBuild': '3.0.1+18',
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(
        database.collection('inviteCodes').doc(inviteCode),
        {
          'userId': user.uid,
          'email': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(ledgerReference, {
        'memberIds': [user.uid],
        'memberEmails': [user.email],
        'createdBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit().timeout(const Duration(seconds: 20));
    } catch (error) {
      debugPrint('Background account metadata sync failed: $error');
    }
  }

  void _setConnectionError(Object error) {
    final message = error is FirebaseException
        ? _firestoreErrorMessage(error)
        : error.toString();
    if (mounted) {
      setState(() {
        _loadingTransactions = false;
        _connectionError = message;
      });
    }
  }

  void _selectActiveLedger(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.docs.isEmpty) {
      return;
    }

    final sortedDocuments = snapshot.docs.toList()
      ..sort((a, b) {
        final aShared = a.id.startsWith('shared_');
        final bShared = b.id.startsWith('shared_');
        if (aShared != bShared) {
          return aShared ? 1 : -1;
        }
        final aDate = a.data()['updatedAt'];
        final bDate = b.data()['updatedAt'];
        final aMilliseconds = aDate is Timestamp
            ? aDate.millisecondsSinceEpoch
            : 0;
        final bMilliseconds = bDate is Timestamp
            ? bDate.millisecondsSinceEpoch
            : 0;
        return bMilliseconds.compareTo(aMilliseconds);
      });

    _ledgerDocuments
      ..clear()
      ..addEntries(
        sortedDocuments.map((document) => MapEntry(document.id, document)),
      );
    final options = sortedDocuments.map((document) {
      final data = document.data();
      return LedgerOption(
        id: document.id,
        name:
            data['name'] as String? ??
            (document.id.startsWith('shared_') ? '공동 가계부' : '내 개인 가계부'),
        memberEmails:
            (data['memberEmails'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const [],
      );
    }).toList();
    if (mounted) {
      setState(() => _availableLedgers = options);
    }

    final personalLedgerId = 'personal_${widget.user.uid}';
    final selected =
        _ledgerDocuments[_preferredLedgerId] ??
        _ledgerDocuments[_ledgerId] ??
        _ledgerDocuments[personalLedgerId] ??
        sortedDocuments.first;
    _activateLedger(selected);
  }

  void _switchLedger(String ledgerId) {
    final document = _ledgerDocuments[ledgerId];
    if (document == null || ledgerId == _ledgerId) {
      return;
    }
    _preferredLedgerId = ledgerId;
    _activateLedger(document);
    unawaited(
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
            'activeLedgerId': ledgerId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 15))
          .catchError((Object error) {
            debugPrint('Active ledger save failed: $error');
          }),
    );
  }

  Future<int> _importPersonalTransactions() async {
    if (!_ledgerId.startsWith('shared_')) {
      throw StateError('공동 가계부를 먼저 선택해 주세요.');
    }
    final database = FirebaseFirestore.instance;
    final personalLedgerId = 'personal_${widget.user.uid}';
    final source = await database
        .collection('ledgers')
        .doc(personalLedgerId)
        .collection('transactions')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    final sourceDocuments = source.docs
        .where((document) => document.data()['deletedAt'] is! Timestamp)
        .toList();
    if (sourceDocuments.isEmpty) {
      return 0;
    }

    final target = database
        .collection('ledgers')
        .doc(_ledgerId)
        .collection('transactions');
    const batchSize = 400;
    for (var start = 0; start < sourceDocuments.length; start += batchSize) {
      final end = (start + batchSize < sourceDocuments.length)
          ? start + batchSize
          : sourceDocuments.length;
      final batch = database.batch();
      for (final document in sourceDocuments.sublist(start, end)) {
        final importedId = 'import_${widget.user.uid}_${document.id}';
        batch.set(target.doc(importedId), {
          ...document.data(),
          'importedFromLedgerId': personalLedgerId,
          'importedFromTransactionId': document.id,
          'importedBy': widget.user.uid,
          'importedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit().timeout(const Duration(seconds: 30));
    }
    return sourceDocuments.length;
  }

  void _activateLedger(DocumentSnapshot<Map<String, dynamic>> ledgerDocument) {
    final data = ledgerDocument.data() ?? {};
    final memberEmails =
        (data['memberEmails'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        [];
    final memberIds =
        (data['memberIds'] as List<dynamic>?)?.whereType<String>().toList() ??
        [];

    if (_ledgerId == ledgerDocument.id) {
      if (mounted) {
        setState(() {
          _ledgerName = data['name'] as String? ?? '모아봄';
          _ledgerMemberEmails = memberEmails;
          _ledgerMemberIds = memberIds;
          _ledgerColorKey = data['colorKey'] as String? ?? 'pink';
        });
      }
      return;
    }

    _transactionSubscription?.cancel();
    _categorySubscription?.cancel();
    _ledgerId = ledgerDocument.id;

    if (mounted) {
      setState(() {
        _ledgerName = data['name'] as String? ?? '모아봄';
        _ledgerMemberEmails = memberEmails;
        _ledgerMemberIds = memberIds;
        _ledgerColorKey = data['colorKey'] as String? ?? 'pink';
        _loadingTransactions = true;
        _transactions.clear();
        _deletedTransactions.clear();
        _knownTransactionIds.clear();
        _transactionStreamInitialized = false;
      });
    }

    final ledgerReference = FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId);

    _categorySubscription = ledgerReference.snapshots().listen((snapshot) {
      final ledgerData = snapshot.data();
      if (ledgerData == null || !mounted) {
        return;
      }
      final expenses = (ledgerData['expenseCategories'] as List<dynamic>?)
          ?.whereType<String>()
          .toList();
      final incomes = (ledgerData['incomeCategories'] as List<dynamic>?)
          ?.whereType<String>()
          .toList();
      final emails =
          (ledgerData['memberEmails'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [];
      final memberIds =
          (ledgerData['memberIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [];
      final iconKeys = (ledgerData['categoryIcons'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value.toString()));
      final merchantRules =
          (ledgerData['merchantCategoryRules'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          );
      final merchantTitleRules =
          (ledgerData['merchantTitleRules'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          );
      final monthlyBudget = (ledgerData['monthlyBudget'] as num?)?.toInt() ?? 0;
      final categoryBudgets =
          (ledgerData['categoryBudgets'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          <String, int>{};
      final monthlySavingsGoal =
          (ledgerData['monthlySavingsGoal'] as num?)?.toInt() ?? 0;
      final recurringRules =
          (ledgerData['recurringRules'] as List<dynamic>? ?? const [])
              .map(RecurringTransactionRule.fromMap)
              .whereType<RecurringTransactionRule>()
              .toList();
      setState(() {
        _ledgerName = ledgerData['name'] as String? ?? '모아봄';
        _ledgerMemberEmails = emails;
        _ledgerMemberIds = memberIds;
        _ledgerColorKey = ledgerData['colorKey'] as String? ?? 'pink';
        _expenseCategories = expenses == null || expenses.isEmpty
            ? [...defaultExpenseCategories]
            : [...expenses, if (!expenses.contains('환불')) '환불'];
        _incomeCategories = incomes == null || incomes.isEmpty
            ? [...defaultIncomeCategories]
            : incomes;
        _categoryIconKeys = {...defaultCategoryIconKeys, ...?iconKeys};
        _merchantCategoryRules = {...?merchantRules};
        _merchantTitleRules = {...?merchantTitleRules};
        _monthlyBudget = monthlyBudget;
        _categoryBudgets = categoryBudgets;
        _monthlySavingsGoal = monthlySavingsGoal;
        _recurringRules = recurringRules;
        _runtimeCategoryIconKeys
          ..clear()
          ..addAll(_categoryIconKeys);
      });
      unawaited(_generateRecurringTransactions());
      unawaited(_updateBudgetServices());
    });

    _transactionSubscription = ledgerReference
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            BudgetTransaction? newPartnerTransaction;
            final transactions = snapshot.docs.map((document) {
              final transactionData = document.data();
              final timestamp = transactionData['date'];
              final deletedTimestamp = transactionData['deletedAt'];
              final transaction = BudgetTransaction(
                id: document.id,
                title: transactionData['title'] as String? ?? '이름 없음',
                category: transactionData['category'] as String? ?? '기타',
                amount: (transactionData['amount'] as num?)?.toInt() ?? 0,
                type: transactionData['type'] == TransactionType.income.name
                    ? TransactionType.income
                    : TransactionType.expense,
                date: timestamp is Timestamp
                    ? timestamp.toDate()
                    : DateTime.now(),
                memo: transactionData['memo'] as String? ?? '',
                createdBy: transactionData['createdBy'] as String? ?? '',
                sourceApp: transactionData['sourceApp'] as String? ?? '',
                installmentMonths:
                    (transactionData['installmentMonths'] as num?)?.toInt(),
                recognitionConfidence:
                    (transactionData['recognitionConfidence'] as num?)
                        ?.toDouble(),
                sourceMessageId:
                    transactionData['sourceMessageId'] as String? ?? '',
                isRefund: transactionData['isRefund'] as bool? ?? false,
                deletedAt: deletedTimestamp is Timestamp
                    ? deletedTimestamp.toDate()
                    : null,
              );
              if (_transactionStreamInitialized &&
                  !_knownTransactionIds.contains(document.id) &&
                  transaction.createdBy.isNotEmpty &&
                  transaction.createdBy != widget.user.uid &&
                  transaction.deletedAt == null) {
                newPartnerTransaction ??= transaction;
              }
              return transaction;
            }).toList();

            _knownTransactionIds
              ..clear()
              ..addAll(snapshot.docs.map((document) => document.id));
            _transactionStreamInitialized = true;

            if (mounted) {
              setState(() {
                _transactions
                  ..clear()
                  ..addAll(
                    transactions.where((item) => item.deletedAt == null),
                  );
                _deletedTransactions
                  ..clear()
                  ..addAll(
                    transactions.where((item) => item.deletedAt != null),
                  );
                _loadingTransactions = false;
                _isFromCache = snapshot.metadata.isFromCache;
                _hasPendingWrites = snapshot.metadata.hasPendingWrites;
                _connectionError = null;
              });
              unawaited(_updateBudgetServices());
              if (newPartnerTransaction != null) {
                _showMessage(
                  '함께 쓰는 사람이 ${newPartnerTransaction!.title} 내역을 추가했어요.',
                );
              }
            }
          },
          onError: (Object error) {
            _setConnectionError(error);
          },
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transactionSubscription?.cancel();
    _ledgerSubscription?.cancel();
    _categorySubscription?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshPendingPaymentCount() async {
    try {
      final count = await SmsPlatformService.getPendingPaymentCount();
      if (mounted) {
        setState(() => _pendingPaymentCount = count);
      }
    } on PlatformException {
      // Android 외 플랫폼에서는 자동등록 대기 건수를 표시하지 않습니다.
    }
  }

  Future<void> _openPendingPayments() async {
    List<PendingPayment> pendingPayments;
    try {
      pendingPayments = await SmsPlatformService.getPendingPayments();
    } on PlatformException {
      pendingPayments = const [];
    }
    if (!mounted) {
      return;
    }
    if (pendingPayments.isNotEmpty) {
      final action = await showModalBottomSheet<PendingPaymentsAction>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PendingPaymentsSheet(payments: pendingPayments),
      );
      if (action == null || !mounted) {
        return;
      }
      if (action.rawMessages.isNotEmpty) {
        final remaining = await SmsPlatformService.removePendingPayments(
          action.rawMessages,
        );
        if (mounted) {
          setState(() => _pendingPaymentCount = remaining);
          _showMessage('${action.rawMessages.length}건을 알림함에서 제외했습니다.');
        }
      } else if (action.payment != null) {
        await _reviewPendingPayment(action.payment!);
      }
      return;
    }

    final openSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('자동등록 알림함'),
        content: const Text(
          '현재 확인할 결제 문자·Push가 없습니다.\n\n'
          '금액과 승인·결제·입금·출금 같은 단어가 포함된 새 알림이 오면 '
          '여기에 저장 대기 건수가 표시됩니다.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('알림 접근 설정'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await SmsPlatformService.openNotificationAccessSettings();
    }
  }

  Future<void> _reviewPendingPayment(PendingPayment pendingPayment) async {
    var draft = SmsTransactionParser.parse(
      pendingPayment.rawMessage,
      receivedAt: pendingPayment.receivedAt,
    );
    if (draft == null) {
      await SmsPlatformService.removePendingPayments([
        pendingPayment.rawMessage,
      ]);
      await _refreshPendingPaymentCount();
      if (mounted) {
        _showMessage('결제 금액을 찾지 못해 알림함에서 제외했습니다.');
      }
      return;
    }
    draft = _applyLearnedCategory(draft);
    final outcome = await _openAddTransaction(draft: draft);
    if (outcome == AddTransactionOutcome.saved ||
        outcome == AddTransactionOutcome.discarded) {
      final remaining = await SmsPlatformService.removePendingPayments([
        pendingPayment.rawMessage,
      ]);
      if (mounted) {
        setState(() => _pendingPaymentCount = remaining);
        if (outcome == AddTransactionOutcome.discarded) {
          _showMessage('잘못 인식된 알림을 대기 목록에서 제외했습니다.');
        }
      }
      _lastPresentedSms = null;
    }
  }

  Future<void> _checkPendingSms() async {
    if (_checkingSms || !mounted) {
      return;
    }

    _checkingSms = true;
    try {
      final pendingPayment = await SmsPlatformService.getPendingSms();
      if (pendingPayment == null) {
        if (mounted) {
          setState(() => _pendingPaymentCount = 0);
        }
        return;
      }
      final rawSms = pendingPayment.rawMessage;
      if (_lastPresentedSms == rawSms) {
        return;
      }

      _lastPresentedSms = rawSms;
      var draft = SmsTransactionParser.parse(
        rawSms,
        receivedAt: pendingPayment.receivedAt,
      );
      if (!mounted) {
        return;
      }

      if (draft == null) {
        await SmsPlatformService.clearPendingSms();
        await _refreshPendingPaymentCount();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('문자에서 결제 금액을 찾지 못했습니다.')));
        _lastPresentedSms = null;
        _checkingSms = false;
        await _checkPendingSms();
        return;
      }

      draft = _applyLearnedCategory(draft);

      final outcome = await _openAddTransaction(draft: draft);
      if (outcome == AddTransactionOutcome.saved ||
          outcome == AddTransactionOutcome.discarded) {
        await SmsPlatformService.clearPendingSms();
        await _refreshPendingPaymentCount();
        if (outcome == AddTransactionOutcome.discarded && mounted) {
          _showMessage('잘못 인식된 알림을 대기 목록에서 제외했습니다.');
        }
        _lastPresentedSms = null;
        _checkingSms = false;
        await _checkPendingSms();
      }
    } on PlatformException {
      // 권한이 거절되었거나 Android 문자 기능을 사용할 수 없는 경우입니다.
    } finally {
      _checkingSms = false;
    }
  }

  Future<void> _generateRecurringTransactions() async {
    if (_ledgerId.isEmpty || _recurringRules.isEmpty) return;
    final now = DateTime.now();
    final enabledIds = _recurringRules
        .where((rule) => rule.enabled)
        .map((rule) => rule.id)
        .join(',');
    final generationKey = '$_ledgerId-${now.year}-${now.month}-$enabledIds';
    if (_recurringGenerationKey == generationKey) return;
    _recurringGenerationKey = generationKey;

    try {
      final collection = FirebaseFirestore.instance
          .collection('ledgers')
          .doc(_ledgerId)
          .collection('transactions');
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      for (final rule in _recurringRules.where((item) => item.enabled)) {
        final candidateDates = <DateTime>[];
        if (rule.cycle == RepeatCycle.monthly) {
          candidateDates.add(
            DateTime(now.year, now.month, rule.day.clamp(1, lastDay), 9),
          );
        } else if (rule.cycle == RepeatCycle.yearly &&
            rule.month == now.month) {
          candidateDates.add(
            DateTime(now.year, now.month, rule.day.clamp(1, lastDay), 9),
          );
        } else if (rule.cycle == RepeatCycle.weekly) {
          for (var day = 1; day <= now.day; day++) {
            final date = DateTime(now.year, now.month, day, 9);
            if (date.weekday == rule.weekday) candidateDates.add(date);
          }
        }
        final safeRuleId = rule.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        for (final date in candidateDates) {
          final endExclusive = rule.endDate == null
              ? null
              : DateTime(
                  rule.endDate!.year,
                  rule.endDate!.month,
                  rule.endDate!.day + 1,
                );
          if (date.isAfter(now) ||
              (endExclusive != null && !date.isBefore(endExclusive))) {
            continue;
          }
          final dateKey =
              '${date.year}${date.month.toString().padLeft(2, '0')}'
              '${date.day.toString().padLeft(2, '0')}';
          final document = collection.doc('recurring_${safeRuleId}_$dateKey');
          final existing = await document.get();
          if (existing.exists) continue;
          var transaction = BudgetTransaction(
            id: document.id,
            title: rule.title,
            category: rule.category,
            amount: rule.amount,
            type: rule.type,
            date: date,
            memo: rule.memo.isEmpty ? '반복 내역 자동등록' : '${rule.memo}\n반복 내역 자동등록',
          );
          if ((rule.confirmBeforeAdding || rule.variableAmount) && mounted) {
            final confirmed = await showModalBottomSheet<BudgetTransaction>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddTransactionSheet(
                initialTransaction: transaction,
                expenseCategories: _expenseCategories,
                incomeCategories: _incomeCategories,
              ),
            );
            if (confirmed == null) continue;
            transaction = confirmed;
          }
          await document.set(transaction.toFirestore(widget.user.uid));
        }
      }
    } catch (error) {
      _recurringGenerationKey = null;
      debugPrint('Recurring transaction generation failed: $error');
    }
  }

  Future<void> _updateBudgetServices() async {
    final now = DateTime.now();
    final expense = totalForType(
      _transactions.where((item) => isSameMonth(item.date, now)).toList(),
      TransactionType.expense,
    );
    try {
      await AppSettingsService.updateHomeWidget(expense, _monthlyBudget);
      final ratio = _monthlyBudget <= 0 ? 0 : expense / _monthlyBudget;
      final threshold = ratio >= 1
          ? 100
          : ratio >= 0.9
          ? 90
          : ratio >= 0.7
          ? 70
          : 0;
      final alertKey = '$_ledgerId-${now.year}-${now.month}-$threshold';
      if (threshold > 0 && _budgetAlertKey != alertKey) {
        _budgetAlertKey = alertKey;
        await AppSettingsService.showBudgetAlert(
          expense,
          _monthlyBudget,
          threshold,
        );
      }
    } on MissingPluginException {
      // Android 외 플랫폼에서는 앱 안의 예산 카드만 표시합니다.
    }
  }

  Future<void> _saveAutomationSettings({
    required int monthlyBudget,
    required Map<String, int> categoryBudgets,
    required int monthlySavingsGoal,
    required List<RecurringTransactionRule> recurringRules,
  }) async {
    await FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId)
        .update({
          'monthlyBudget': monthlyBudget,
          'categoryBudgets': categoryBudgets,
          'monthlySavingsGoal': monthlySavingsGoal,
          'recurringRules': recurringRules.map((rule) => rule.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));
    _recurringGenerationKey = null;
  }

  Future<void> _addTransaction(BudgetTransaction transaction) async {
    if (_ledgerId.isEmpty) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    if (transaction.sourceMessageId.isNotEmpty &&
        _transactions.any(
          (item) => item.sourceMessageId == transaction.sourceMessageId,
        )) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
        message: 'The same notification was already saved.',
      );
    }
    await FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId)
        .collection('transactions')
        .add(transaction.toFirestore(widget.user.uid))
        .timeout(const Duration(seconds: 15));
  }

  SmsTransactionDraft _applyLearnedCategory(SmsTransactionDraft draft) {
    final key = merchantRuleKey(draft.title, draft.type);
    final learned = _merchantCategoryRules[key];
    final learnedTitle = _merchantTitleRules[key];
    final available = draft.type == TransactionType.expense
        ? _expenseCategories
        : _incomeCategories;
    if (learned == null || !available.contains(learned)) {
      return draft;
    }
    return SmsTransactionDraft(
      title: learnedTitle?.trim().isNotEmpty == true
          ? learnedTitle!.trim()
          : draft.title,
      amount: draft.amount,
      category: learned,
      date: draft.date,
      rawMessage: draft.rawMessage,
      type: draft.type,
      sourceApp: draft.sourceApp,
      installmentMonths: draft.installmentMonths,
      confidence: draft.confidence,
      sourceMessageId: draft.sourceMessageId,
      isRefund: draft.isRefund,
    );
  }

  Future<void> _rememberMerchantCategory(
    SmsTransactionDraft draft,
    BudgetTransaction transaction,
  ) async {
    if (!isLearnableMerchantTitle(draft.title) ||
        !isLearnableMerchantTitle(transaction.title)) {
      return;
    }
    final key = merchantRuleKey(draft.title, draft.type);
    _merchantCategoryRules[key] = transaction.category;
    _merchantTitleRules[key] = transaction.title;
    try {
      await FirebaseFirestore.instance
          .collection('ledgers')
          .doc(_ledgerId)
          .update({
            'merchantCategoryRules.$key': transaction.category,
            'merchantTitleRules.$key': transaction.title,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      debugPrint('Merchant category rule save failed: $error');
    }
  }

  Future<AddTransactionOutcome> _openAddTransaction({
    SmsTransactionDraft? draft,
  }) async {
    var discardRequested = false;
    final result = await showModalBottomSheet<BudgetTransaction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddTransactionSheet(
        initialDraft: draft,
        expenseCategories: _expenseCategories,
        incomeCategories: _incomeCategories,
        onDiscard: draft == null
            ? null
            : () {
                discardRequested = true;
                Navigator.of(sheetContext).pop();
              },
      ),
    );

    if (result != null) {
      try {
        await _addTransaction(result);
        if (draft != null) {
          unawaited(_rememberMerchantCategory(draft, result));
        }
        if (mounted) {
          _showMessage('거래가 저장되었습니다.');
        }
        return AddTransactionOutcome.saved;
      } on FirebaseException catch (error) {
        debugPrint(
          'Firestore transaction save failed: ${error.code} ${error.message}',
        );
        if (mounted) {
          _showMessage(_firestoreErrorMessage(error));
        }
        return AddTransactionOutcome.dismissed;
      }
    }
    return discardRequested
        ? AddTransactionOutcome.discarded
        : AddTransactionOutcome.dismissed;
  }

  Future<void> _openTransactionActions(BudgetTransaction transaction) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      barrierColor: const Color(0x990F0710),
      backgroundColor: const Color(0xFFFFFBFD),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Icon(categoryIcon(transaction.category)),
                ),
                title: Text(
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${formatWon(transaction.amount)}원'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('수정하기'),
                onTap: () => Navigator.of(sheetContext).pop('edit'),
              ),
              Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB4C3)),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFB42335),
                  ),
                  title: const Text(
                    '삭제하기',
                    style: TextStyle(
                      color: Color(0xFFB42335),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFB42335),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop('delete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'edit') {
      await _openEditTransaction(transaction);
    } else if (action == 'delete') {
      await _confirmDeleteTransaction(transaction);
    }
  }

  Future<void> _openEditTransaction(BudgetTransaction transaction) async {
    final edited = await showModalBottomSheet<BudgetTransaction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        initialTransaction: transaction,
        expenseCategories: _expenseCategories,
        incomeCategories: _incomeCategories,
      ),
    );
    if (edited == null || _ledgerId.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('ledgers')
          .doc(_ledgerId)
          .collection('transactions')
          .doc(transaction.id)
          .update(
            edited.toFirestore(
              widget.user.uid,
              includeCreatedAt: false,
              includeCreatedBy: false,
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        _showMessage('내역을 수정했습니다.');
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage(_firestoreErrorMessage(error));
      }
    } on TimeoutException {
      if (mounted) {
        _showMessage('수정 시간이 초과되었습니다. 인터넷 연결을 확인해 주세요.');
      }
    }
  }

  Future<void> _confirmDeleteTransaction(BudgetTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('내역을 삭제할까요?'),
        content: Text(
          '${transaction.title} · ${formatWon(transaction.amount)}원\n'
          '삭제한 내역은 휴지통에서 다시 복원할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || _ledgerId.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('ledgers')
          .doc(_ledgerId)
          .collection('transactions')
          .doc(transaction.id)
          .update({
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedBy': widget.user.uid,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        _showMessage('내역을 휴지통으로 옮겼습니다.');
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        _showMessage(_firestoreErrorMessage(error));
      }
    } on TimeoutException {
      if (mounted) {
        _showMessage('삭제 시간이 초과되었습니다. 인터넷 연결을 확인해 주세요.');
      }
    }
  }

  Future<void> _restoreTransaction(BudgetTransaction transaction) async {
    await FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId)
        .collection('transactions')
        .doc(transaction.id)
        .update({
          'deletedAt': FieldValue.delete(),
          'deletedBy': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));
    if (mounted) {
      _showMessage('내역을 복원했습니다.');
    }
  }

  Future<void> _deleteTransactionPermanently(
    BudgetTransaction transaction,
  ) async {
    await FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId)
        .collection('transactions')
        .doc(transaction.id)
        .delete()
        .timeout(const Duration(seconds: 15));
    if (mounted) {
      _showMessage('내역을 완전히 삭제했습니다.');
    }
  }

  Future<void> _openTrash() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TrashPage(
          transactions: _deletedTransactions,
          onRestore: _restoreTransaction,
          onDeletePermanently: _deleteTransactionPermanently,
        ),
      ),
    );
  }

  void _copyCsvBackup() {
    if (_transactions.isEmpty) {
      _showMessage('백업할 내역이 없습니다.');
      return;
    }
    Clipboard.setData(ClipboardData(text: transactionsToCsv(_transactions)));
    _showMessage('엑셀용 CSV 내역을 복사했습니다.');
  }

  Future<void> _exportCsvFile() async {
    if (_transactions.isEmpty) {
      _showMessage('내보낼 내역이 없습니다.');
      return;
    }
    try {
      final now = DateTime.now();
      final saved = await AppSettingsService.exportCsv(
        '모아봄_${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}.csv',
        transactionsToCsv(_transactions),
      );
      if (saved == true && mounted) _showMessage('CSV 파일을 저장했습니다.');
    } on PlatformException catch (error) {
      if (mounted) _showMessage('파일을 저장하지 못했습니다: ${error.code}');
    }
  }

  Future<void> _exportCsvRange() async {
    if (_transactions.isEmpty) return;
    final dates = _transactions.map((item) => item.date).toList()..sort();
    if (!mounted) return;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: dates.first, end: dates.last),
      helpText: 'CSV로 내보낼 기간 선택',
    );
    if (range == null) return;
    final end = range.end.add(const Duration(days: 1));
    final selected = _transactions
        .where(
          (item) => !item.date.isBefore(range.start) && item.date.isBefore(end),
        )
        .toList();
    if (selected.isEmpty) {
      _showMessage('선택한 기간에 내역이 없습니다.');
      return;
    }
    final saved = await AppSettingsService.exportCsv(
      '모아봄_${range.start.year}${range.start.month.toString().padLeft(2, '0')}'
      '_${range.end.year}${range.end.month.toString().padLeft(2, '0')}.csv',
      transactionsToCsv(selected),
    );
    if (saved == true && mounted) _showMessage('${selected.length}건을 저장했습니다.');
  }

  Future<void> _exportFullBackup() async {
    final content = jsonEncode({
      'format': 'shared-budget-backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'ledger': {
        'name': _ledgerName,
        'monthlyBudget': _monthlyBudget,
        'categoryBudgets': _categoryBudgets,
        'monthlySavingsGoal': _monthlySavingsGoal,
        'expenseCategories': _expenseCategories,
        'incomeCategories': _incomeCategories,
        'categoryIcons': _categoryIconKeys,
        'recurringRules': _recurringRules.map((item) => item.toMap()).toList(),
      },
      'transactions': _transactions
          .map(
            (item) => {
              'title': item.title,
              'category': item.category,
              'amount': item.amount,
              'type': item.type.name,
              'date': item.date.toIso8601String(),
              'memo': item.memo,
              'sourceApp': item.sourceApp,
              'installmentMonths': item.installmentMonths,
              'isRefund': item.isRefund,
              'sourceMessageId': item.sourceMessageId,
            },
          )
          .toList(),
    });
    final now = DateTime.now();
    final saved = await AppSettingsService.exportCsv(
      '모아봄_전체백업_${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}.json',
      content,
      mimeType: 'application/json',
    );
    if (saved == true && mounted) _showMessage('전체 백업 파일을 저장했습니다.');
  }

  Future<void> _importFullBackup() async {
    try {
      final content = await AppSettingsService.importCsv();
      if (content == null || content.trim().isEmpty || !mounted) return;
      final decoded = jsonDecode(content);
      if (decoded is! Map || decoded['format'] != 'shared-budget-backup') {
        throw const FormatException('모아봄 전체 백업 파일이 아닙니다.');
      }
      final ledger = Map<String, dynamic>.from(decoded['ledger'] as Map? ?? {});
      final rawTransactions = (decoded['transactions'] as List? ?? const []);
      final restored = <BudgetTransaction>[];
      for (var index = 0; index < rawTransactions.length; index++) {
        final map = Map<String, dynamic>.from(rawTransactions[index] as Map);
        final date = DateTime.tryParse(map['date'] as String? ?? '');
        final amount = (map['amount'] as num?)?.toInt() ?? 0;
        if (date == null || amount <= 0) continue;
        final sourceId = map['sourceMessageId'] as String? ?? '';
        restored.add(
          BudgetTransaction(
            id: 'backup_$index',
            title: map['title'] as String? ?? '이름 없음',
            category: map['category'] as String? ?? '기타',
            amount: amount,
            type: map['type'] == 'income'
                ? TransactionType.income
                : TransactionType.expense,
            date: date,
            memo: map['memo'] as String? ?? '',
            sourceApp: map['sourceApp'] as String? ?? '',
            installmentMonths: (map['installmentMonths'] as num?)?.toInt(),
            isRefund: map['isRefund'] as bool? ?? false,
            sourceMessageId: sourceId.isEmpty
                ? stableMessageId(
                    '${date.toIso8601String()}|${map['title']}|$amount|$index',
                  )
                : sourceId,
          ),
        );
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('전체 백업 복원'),
          content: Text(
            '설정과 내역 ${restored.length}건을 현재 가계부에 복원할까요?\n'
            '이미 같은 알림으로 저장된 내역은 건너뜁니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('복원'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final database = FirebaseFirestore.instance;
      final ledgerReference = database.collection('ledgers').doc(_ledgerId);
      await ledgerReference.update({
        if ((ledger['name'] as String? ?? '').trim().isNotEmpty)
          'name': ledger['name'],
        'monthlyBudget': (ledger['monthlyBudget'] as num?)?.toInt() ?? 0,
        'categoryBudgets': ledger['categoryBudgets'] ?? {},
        'monthlySavingsGoal':
            (ledger['monthlySavingsGoal'] as num?)?.toInt() ?? 0,
        'expenseCategories': ledger['expenseCategories'] ?? _expenseCategories,
        'incomeCategories': ledger['incomeCategories'] ?? _incomeCategories,
        'categoryIcons': ledger['categoryIcons'] ?? _categoryIconKeys,
        'recurringRules': ledger['recurringRules'] ?? const [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final existingIds = _transactions
          .map((item) => item.sourceMessageId)
          .where((value) => value.isNotEmpty)
          .toSet();
      final unique = restored
          .where((item) => existingIds.add(item.sourceMessageId))
          .toList();
      for (var start = 0; start < unique.length; start += 400) {
        final end = start + 400 < unique.length ? start + 400 : unique.length;
        final batch = database.batch();
        for (final item in unique.sublist(start, end)) {
          batch.set(
            ledgerReference.collection('transactions').doc(),
            item.toFirestore(widget.user.uid),
          );
        }
        await batch.commit();
      }
      if (mounted) _showMessage('설정과 내역 ${unique.length}건을 복원했습니다.');
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('전체 백업을 복원하지 못했습니다.');
    }
  }

  Future<void> _importCsvFile() async {
    try {
      final content = await AppSettingsService.importCsv();
      if (content == null || content.trim().isEmpty || !mounted) return;
      final existingIds = _transactions
          .map((item) => item.sourceMessageId)
          .where((value) => value.isNotEmpty)
          .toSet();
      final transactions = transactionsFromCsv(
        content,
      ).where((item) => existingIds.add(item.sourceMessageId)).toList();
      if (transactions.isEmpty) {
        _showMessage('가져올 수 있는 내역을 찾지 못했습니다.');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('CSV 내역 가져오기'),
          content: Text('${transactions.length}건을 현재 가계부에 추가할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('가져오기'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final database = FirebaseFirestore.instance;
      final collection = database
          .collection('ledgers')
          .doc(_ledgerId)
          .collection('transactions');
      for (var start = 0; start < transactions.length; start += 400) {
        final end = start + 400 < transactions.length
            ? start + 400
            : transactions.length;
        final batch = database.batch();
        for (final transaction in transactions.sublist(start, end)) {
          batch.set(collection.doc(), transaction.toFirestore(widget.user.uid));
        }
        await batch.commit();
      }
      if (mounted) _showMessage('${transactions.length}건을 가져왔습니다.');
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } on PlatformException catch (error) {
      if (mounted) _showMessage('파일을 열지 못했습니다: ${error.code}');
    }
  }

  Future<void> _openAdvancedSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AdvancedSettingsPage(
          monthlyBudget: _monthlyBudget,
          categoryBudgets: _categoryBudgets,
          monthlySavingsGoal: _monthlySavingsGoal,
          recurringRules: _recurringRules,
          expenseCategories: _expenseCategories,
          incomeCategories: _incomeCategories,
          onSaveAutomation: _saveAutomationSettings,
          onExportCsv: _exportCsvFile,
          onExportCsvRange: _exportCsvRange,
          onImportCsv: _importCsvFile,
          onExportFullBackup: _exportFullBackup,
          onImportFullBackup: _importFullBackup,
          onLockChanged: (enabled) {
            if (mounted) {
              setState(() {
                _appLockEnabled = enabled;
                _appUnlocked = true;
                if (!enabled) _biometricEnabled = false;
              });
            }
          },
          onBiometricChanged: (enabled) {
            if (mounted) setState(() => _biometricEnabled = enabled);
          },
        ),
      ),
    );
  }

  Future<void> _saveCategories({
    required List<String> expenses,
    required List<String> incomes,
    required Map<String, String> icons,
  }) async {
    await FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId)
        .update({
          'expenseCategories': expenses,
          'incomeCategories': incomes,
          'categoryIcons': icons,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));
    _categoryIconKeys = {...icons};
    _runtimeCategoryIconKeys
      ..clear()
      ..addAll(icons);
  }

  Future<void> _updateLedgerAppearance(String name, String colorKey) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId)
        .update({
          'name': trimmedName,
          'colorKey': colorKey,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> _openCategoryManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CategoryManagerPage(
          expenseCategories: _expenseCategories,
          incomeCategories: _incomeCategories,
          categoryIcons: _categoryIconKeys,
          onSave: _saveCategories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_lockLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_appLockEnabled && !_appUnlocked) {
      return AppPinUnlockPage(
        onUnlocked: () => setState(() => _appUnlocked = true),
        biometricEnabled: _biometricEnabled,
      );
    }
    final pages = [
      HomePage(
        transactions: _transactions,
        isLoading: _loadingTransactions,
        monthlyBudget: _monthlyBudget,
        categoryBudgets: _categoryBudgets,
        monthlySavingsGoal: _monthlySavingsGoal,
        pendingPaymentCount: _pendingPaymentCount,
        onNotificationsPressed: _openPendingPayments,
        onSettingsPressed: _openAdvancedSettings,
        syncLabel: _hasPendingWrites
            ? '저장 중'
            : _isFromCache
            ? '오프라인'
            : '동기화됨',
        onViewAll: () => setState(() => _currentIndex = 1),
        onTransactionTap: _openTransactionActions,
      ),
      TransactionsPage(
        transactions: _transactions,
        isLoading: _loadingTransactions,
        onTransactionTap: _openTransactionActions,
      ),
      StatisticsPage(
        transactions: _transactions,
        isLoading: _loadingTransactions,
      ),
      TogetherPage(
        user: widget.user,
        onManageCategories: _openCategoryManager,
        onOpenTrash: _openTrash,
        onCopyCsvBackup: _copyCsvBackup,
        onOpenAdvancedSettings: _openAdvancedSettings,
        availableLedgers: _availableLedgers,
        onSelectLedger: _switchLedger,
        onImportPersonalTransactions: _importPersonalTransactions,
        ledgerId: _ledgerId,
        ledgerName: _ledgerName,
        memberEmails: _ledgerMemberEmails,
        memberIds: _ledgerMemberIds,
        transactions: _transactions,
        currentUserId: widget.user.uid,
        ledgerColorKey: _ledgerColorKey,
        onUpdateLedgerAppearance: _updateLedgerAppearance,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: SoftPastelBackground(
        child: Column(
          children: [
            if (_connectionError != null)
              SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Color(0xFFBE123C),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _connectionError!,
                          style: const TextStyle(
                            color: Color(0xFF9F1239),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _connectFirestore,
                        child: const Text('재시도'),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: pages),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex < 2
          ? Container(
              decoration: BoxDecoration(
                gradient: appGradient,
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x45D95B90),
                    blurRadius: 22,
                    offset: Offset(0, 9),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                backgroundColor: Colors.transparent,
                elevation: 0,
                focusElevation: 0,
                highlightElevation: 0,
                onPressed: () {
                  if (_ledgerId.isEmpty) {
                    _showMessage(
                      _connectingFirestore
                          ? 'Firebase에서 가계부를 불러오는 중입니다.'
                          : 'Firebase가 연결되지 않았습니다. 다시 연결합니다.',
                    );
                    if (!_connectingFirestore) {
                      _connectFirestore();
                    }
                    return;
                  }
                  _openAddTransaction();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  '내역 추가',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            )
          : null,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1FA64D72),
                blurRadius: 26,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: '홈',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: '내역',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: '통계',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: '함께쓰기',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _firestoreErrorMessage(FirebaseException error) {
  return switch (error.code) {
    'already-exists' => '이미 저장한 문자·Push 내역입니다.',
    'permission-denied' => '저장 권한이 없습니다. Firestore 보안 규칙을 확인해 주세요.',
    'unavailable' => 'Firebase에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.',
    'not-found' => 'Firestore 데이터베이스가 아직 생성되지 않았습니다.',
    'unauthenticated' => '로그인이 만료되었습니다. 다시 로그인해 주세요.',
    _ => '저장하지 못했습니다. 오류: ${error.code}',
  };
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.transactions,
    required this.isLoading,
    required this.monthlyBudget,
    required this.categoryBudgets,
    required this.monthlySavingsGoal,
    required this.pendingPaymentCount,
    required this.onNotificationsPressed,
    required this.onSettingsPressed,
    required this.syncLabel,
    required this.onViewAll,
    required this.onTransactionTap,
  });

  final List<BudgetTransaction> transactions;
  final bool isLoading;
  final int monthlyBudget;
  final Map<String, int> categoryBudgets;
  final int monthlySavingsGoal;
  final int pendingPaymentCount;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onSettingsPressed;
  final String syncLabel;
  final VoidCallback onViewAll;
  final ValueChanged<BudgetTransaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlyTransactions = transactions
        .where((item) => isSameMonth(item.date, now))
        .toList();
    final income = totalForType(monthlyTransactions, TransactionType.income);
    final expense = totalForType(monthlyTransactions, TransactionType.expense);
    final todayExpense = totalForType(
      transactions
          .where(
            (item) =>
                item.date.year == now.year &&
                item.date.month == now.month &&
                item.date.day == now.day,
          )
          .toList(),
      TransactionType.expense,
    );
    final averageDailyExpense = now.day == 0 ? 0 : (expense / now.day).round();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverList.list(
              children: [
                _HomeHeader(
                  pendingPaymentCount: pendingPaymentCount,
                  onNotificationsPressed: onNotificationsPressed,
                  onSettingsPressed: onSettingsPressed,
                  syncLabel: syncLabel,
                ),
                const SizedBox(height: 22),
                _SummaryCard(
                  income: income,
                  expense: expense,
                  month: now.month,
                ),
                if (monthlyBudget > 0) ...[
                  const SizedBox(height: 14),
                  BudgetProgressCard(expense: expense, budget: monthlyBudget),
                ],
                if (monthlyBudget > 0 || categoryBudgets.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  FinancialCoachCard(
                    transactions: monthlyTransactions,
                    monthlyBudget: monthlyBudget,
                    categoryBudgets: categoryBudgets,
                    monthlySavingsGoal: monthlySavingsGoal,
                    dayOfMonth: now.day,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _HomeInsightCard(
                        label: '오늘 지출',
                        value: '${formatWon(todayExpense)}원',
                        icon: Icons.today_rounded,
                        color: const Color(0xFFE86A9D),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HomeInsightCard(
                        label: '하루 평균',
                        value: '${formatWon(averageDailyExpense)}원',
                        icon: Icons.insights_rounded,
                        color: const Color(0xFF8B75D7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '최근 내역',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(onPressed: onViewAll, child: const Text('전체보기')),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: isLoading
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                : transactions.isEmpty
                ? const SliverToBoxAdapter(child: _EmptyTransactions())
                : SliverList.separated(
                    itemCount: transactions.take(5).length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionTile(
                        transaction: transaction,
                        onTap: () => onTransactionTap(transaction),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.pendingPaymentCount,
    required this.onNotificationsPressed,
    required this.onSettingsPressed,
    required this.syncLabel,
  });

  final int pendingPaymentCount;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onSettingsPressed;
  final String syncLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: appGradient,
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2EE85D93),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '모아봄',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: syncLabel == '동기화됨'
                          ? AppColors.mint
                          : syncLabel == '저장 중'
                          ? Colors.orange
                          : AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      syncLabel,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            onPressed: onSettingsPressed,
            color: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.tune_rounded),
            tooltip: '생활 설정',
          ),
        ),
        const SizedBox(width: 7),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                onPressed: onNotificationsPressed,
                color: AppColors.deepRose,
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: '자동등록 알림함',
              ),
            ),
            if (pendingPaymentCount > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE84D83),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    pendingPaymentCount > 99 ? '99+' : '$pendingPaymentCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.expense,
    required this.budget,
  });

  final int expense;
  final int budget;

  @override
  Widget build(BuildContext context) {
    final ratio = budget <= 0 ? 0.0 : expense / budget;
    final over = expense > budget;
    final color = over ? AppColors.coral : AppColors.deepRose;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: softCardDecoration(
        color: over ? const Color(0xFFFFF0F1) : const Color(0xFFFFF8FB),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  over ? Icons.warning_amber_rounded : Icons.savings_outlined,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      over ? '이번 달 예산을 초과했어요' : '이번 달 예산',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      over
                          ? '${formatWon(expense - budget)}원 초과'
                          : '${formatWon(budget - expense)}원 남았어요',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 9,
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class FinancialCoachCard extends StatelessWidget {
  const FinancialCoachCard({
    super.key,
    required this.transactions,
    required this.monthlyBudget,
    required this.categoryBudgets,
    required this.monthlySavingsGoal,
    required this.dayOfMonth,
  });

  final List<BudgetTransaction> transactions;
  final int monthlyBudget;
  final Map<String, int> categoryBudgets;
  final int monthlySavingsGoal;
  final int dayOfMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final expense = totalForType(transactions, TransactionType.expense);
    final income = totalForType(transactions, TransactionType.income);
    final projected = dayOfMonth <= 0
        ? expense
        : (expense / dayOfMonth * lastDay).round();
    final remainingDays = lastDay - dayOfMonth + 1;
    final remainingBudget = monthlyBudget - expense;
    final dailyAvailable = monthlyBudget <= 0 || remainingBudget <= 0
        ? 0
        : (remainingBudget / remainingDays).floor();
    final saved = income - expense > 0 ? income - expense : 0;
    final budgetRatio = monthlyBudget <= 0 ? 0.0 : expense / monthlyBudget;
    final categoryTotals = <String, int>{};
    for (final item in transactions.where(
      (item) => item.type == TransactionType.expense && !item.isRefund,
    )) {
      categoryTotals.update(
        item.category,
        (value) => value + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    final watchedCategories =
        categoryBudgets.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) {
            final first = (categoryTotals[a.key] ?? 0) / a.value;
            final second = (categoryTotals[b.key] ?? 0) / b.value;
            return second.compareTo(first);
          });
    final message = budgetRatio <= 0.5
        ? '지금 흐름 아주 좋아요. 차분하게 잘 지키고 있어요 ✨'
        : budgetRatio <= 0.8
        ? '조금만 더 천천히 쓰면 이번 달 목표를 지킬 수 있어요.'
        : '남은 기간에는 꼭 필요한 지출부터 확인해 봐요.';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🌷', style: TextStyle(fontSize: 23)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CoachMetric(
                  label: '하루 권장 지출',
                  value: '${formatWon(dailyAvailable)}원',
                  icon: Icons.today_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CoachMetric(
                  label: '월말 예상 지출',
                  value: '${formatWon(projected)}원',
                  icon: Icons.auto_graph_rounded,
                ),
              ),
            ],
          ),
          if (monthlySavingsGoal > 0) ...[
            const SizedBox(height: 14),
            Text(
              '저축 목표 ${formatWon(saved)} / ${formatWon(monthlySavingsGoal)}원',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (saved / monthlySavingsGoal).clamp(0, 1),
                minHeight: 7,
                color: AppColors.mint,
                backgroundColor: AppColors.mint.withValues(alpha: 0.12),
              ),
            ),
          ],
          if (watchedCategories.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...watchedCategories.take(3).map((entry) {
              final used = categoryTotals[entry.key] ?? 0;
              final ratio = used / entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Row(
                  children: [
                    Icon(categoryIcon(entry.key), size: 17),
                    const SizedBox(width: 7),
                    Expanded(child: Text(entry.key)),
                    Text(
                      '${formatWon(used)} / ${formatWon(entry.value)}원',
                      style: TextStyle(
                        fontSize: 11,
                        color: ratio >= 1 ? AppColors.coral : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _CoachMetric extends StatelessWidget {
  const _CoachMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _HomeInsightCard extends StatelessWidget {
  const _HomeInsightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, color, 0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.month,
  });

  final int income;
  final int expense;
  final int month;

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;

    return Container(
      padding: const EdgeInsets.all(22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: appGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33E86A9D),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -32,
            top: -42,
            child: _PastelOrb(size: 130, color: Color(0x26FFFFFF)),
          ),
          const Positioned(
            right: 62,
            bottom: -52,
            child: _PastelOrb(size: 100, color: Color(0x15FFFFFF)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$month월 남은 금액',
                style: const TextStyle(color: Color(0xFFFFEAF3), fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatWon(balance)}원',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: '수입',
                      amount: income,
                      icon: Icons.south_west_rounded,
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.white24),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _SummaryItem(
                      label: '지출',
                      amount: expense,
                      icon: Icons.north_east_rounded,
                    ),
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

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
  });

  final String label;
  final int amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFFFFEAF3))),
              const SizedBox(height: 2),
              Text(
                '${formatWon(amount)}원',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.transactions,
    required this.isLoading,
    required this.onTransactionTap,
  });

  final List<BudgetTransaction> transactions;
  final bool isLoading;
  final ValueChanged<BudgetTransaction> onTransactionTap;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final _searchController = TextEditingController();
  TransactionType? _filterType;
  String? _filterCategory;
  int? _minimumAmount;
  int? _maximumAmount;
  bool _calendarView = false;
  DateTime? _selectedCalendarDay;

  bool get _hasDetailedFilter =>
      _filterType != null ||
      _filterCategory != null ||
      _minimumAmount != null ||
      _maximumAmount != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet(List<String> categories) async {
    var selectedType = _filterType;
    var selectedCategory = _filterCategory;
    final minimumController = TextEditingController(
      text: _minimumAmount?.toString() ?? '',
    );
    final maximumController = TextEditingController(
      text: _maximumAmount?.toString() ?? '',
    );
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '상세 필터',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TransactionType?>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: '수입·지출'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('전체')),
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Text('지출'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Text('수입'),
                  ),
                ],
                onChanged: (value) => setSheetState(() => selectedType = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: '분류'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('전체')),
                  ...categories.map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setSheetState(() => selectedCategory = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minimumController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [WonAmountInputFormatter()],
                      decoration: const InputDecoration(labelText: '최소 금액'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: maximumController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [WonAmountInputFormatter()],
                      decoration: const InputDecoration(labelText: '최대 금액'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      selectedType = null;
                      selectedCategory = null;
                      minimumController.clear();
                      maximumController.clear();
                      Navigator.of(sheetContext).pop(true);
                    },
                    child: const Text('초기화'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: const Text('적용하기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _filterType = selectedType;
        _filterCategory = selectedCategory;
        _minimumAmount = int.tryParse(
          minimumController.text.replaceAll(',', ''),
        );
        _maximumAmount = int.tryParse(
          maximumController.text.replaceAll(',', ''),
        );
      });
    }
    minimumController.dispose();
    maximumController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceMonthlyTransactions = widget.transactions
        .where((item) => isSameMonth(item.date, _selectedMonth))
        .toList();
    final categories =
        sourceMonthlyTransactions.map((item) => item.category).toSet().toList()
          ..sort();
    final query = _searchController.text.trim().toLowerCase();
    final monthlyTransactions = sourceMonthlyTransactions.where((item) {
      final searchable = '${item.title} ${item.category} ${item.memo}'
          .toLowerCase();
      return (query.isEmpty || searchable.contains(query)) &&
          (_filterType == null || item.type == _filterType) &&
          (_filterCategory == null || item.category == _filterCategory) &&
          (_minimumAmount == null || item.amount >= _minimumAmount!) &&
          (_maximumAmount == null || item.amount <= _maximumAmount!);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    final groups = <DateTime, List<BudgetTransaction>>{};
    for (final transaction in monthlyTransactions) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      groups.putIfAbsent(day, () => []).add(transaction);
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '내역',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${monthlyTransactions.length}건',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: () => setState(() {
                    _calendarView = !_calendarView;
                    _selectedCalendarDay ??= DateTime.now();
                  }),
                  icon: Icon(
                    _calendarView
                        ? Icons.view_agenda_outlined
                        : Icons.calendar_month_rounded,
                  ),
                  tooltip: _calendarView ? '목록으로 보기' : '달력으로 보기',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _MonthSelector(
              month: _selectedMonth,
              onPrevious: () {
                setState(() {
                  _selectedMonth = previousMonth(_selectedMonth);
                });
              },
              onNext: () {
                setState(() {
                  _selectedMonth = nextMonth(_selectedMonth);
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '사용처·분류·메모 검색',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: _hasDetailedFilter,
                  child: IconButton.filledTonal(
                    onPressed: () => _openFilterSheet(categories),
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: '상세 필터',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _calendarView
                ? CalendarTransactionsView(
                    month: _selectedMonth,
                    transactions: monthlyTransactions,
                    selectedDay: _selectedCalendarDay,
                    onDaySelected: (day) =>
                        setState(() => _selectedCalendarDay = day),
                    onTransactionTap: widget.onTransactionTap,
                  )
                : groups.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: _EmptyTransactions(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final day = groups.keys.elementAt(index);
                      final dayTransactions = groups[day]!;
                      final dayExpense = totalForType(
                        dayTransactions,
                        TransactionType.expense,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.blush,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      formatDayHeader(day),
                                      style: const TextStyle(
                                        color: AppColors.deepRose,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (dayExpense > 0)
                                    Text(
                                      '지출 ${formatWon(dayExpense)}원',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ...dayTransactions.map(
                              (transaction) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TransactionTile(
                                  transaction: transaction,
                                  showDate: false,
                                  onTap: () =>
                                      widget.onTransactionTap(transaction),
                                ),
                              ),
                            ),
                          ],
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

class CalendarTransactionsView extends StatelessWidget {
  const CalendarTransactionsView({
    super.key,
    required this.month,
    required this.transactions,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onTransactionTap,
  });

  final DateTime month;
  final List<BudgetTransaction> transactions;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<BudgetTransaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final rows = ((leading + days) / 7).ceil();
    final selected = selectedDay != null && isSameMonth(selectedDay!, month)
        ? selectedDay!
        : first;
    final byDay = <int, List<BudgetTransaction>>{};
    for (final item in transactions) {
      byDay.putIfAbsent(item.date.day, () => []).add(item);
    }
    final selectedTransactions = byDay[selected.day] ?? const [];
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: softCardDecoration(),
            child: Column(
              children: [
                Row(
                  children: weekdays
                      .map(
                        (label) => Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: rows * 48,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                    itemCount: leading + days,
                    itemBuilder: (context, index) {
                      if (index < leading) return const SizedBox.shrink();
                      final day = index - leading + 1;
                      final date = DateTime(month.year, month.month, day);
                      final isSelected = selected.day == day;
                      final items = byDay[day] ?? const [];
                      final expense = totalForType(
                        items.cast<BudgetTransaction>(),
                        TransactionType.expense,
                      );
                      return InkWell(
                        onTap: () => onDaySelected(date),
                        borderRadius: BorderRadius.circular(13),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (items.isNotEmpty)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : expense > 0
                                        ? AppColors.coral
                                        : AppColors.mint,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              formatDayHeader(selected),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        Expanded(
          child: selectedTransactions.isEmpty
              ? const Center(child: Text('이날은 기록된 내역이 없어요.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  itemCount: selectedTransactions.length,
                  itemBuilder: (context, index) {
                    final item = selectedTransactions[index];
                    return TransactionTile(
                      transaction: item,
                      showDate: false,
                      onTap: () => onTransactionTap(item),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                ),
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10A64D72),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: '이전 달',
          ),
          Expanded(
            child: Text(
              formatMonth(month),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: '다음 달',
          ),
        ],
      ),
    );
  }
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    required this.transactions,
    required this.isLoading,
  });

  final List<BudgetTransaction> transactions;
  final bool isLoading;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final current = widget.transactions
        .where((item) => isSameMonth(item.date, _selectedMonth))
        .toList();
    final previous = widget.transactions
        .where((item) => isSameMonth(item.date, previousMonth(_selectedMonth)))
        .toList();
    final income = totalForType(current, TransactionType.income);
    final expense = totalForType(current, TransactionType.expense);
    final previousIncome = totalForType(previous, TransactionType.income);
    final previousExpense = totalForType(previous, TransactionType.expense);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '통계',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _MonthSelector(
              month: _selectedMonth,
              onPrevious: () {
                setState(() {
                  _selectedMonth = previousMonth(_selectedMonth);
                });
              },
              onNext: () {
                setState(() {
                  _selectedMonth = nextMonth(_selectedMonth);
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatSummaryCard(
                              label: '수입',
                              amount: income,
                              previousAmount: previousIncome,
                              color: AppColors.mint,
                              icon: Icons.south_west_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatSummaryCard(
                              label: '지출',
                              amount: expense,
                              previousAmount: previousExpense,
                              color: AppColors.coral,
                              icon: Icons.north_east_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BalanceCard(balance: income - expense),
                      const SizedBox(height: 22),
                      _CategoryStatistics(
                        title: '지출 분류',
                        transactions: current
                            .where(
                              (item) =>
                                  item.type == TransactionType.expense &&
                                  !item.isRefund,
                            )
                            .toList(),
                        color: AppColors.coral,
                      ),
                      const SizedBox(height: 14),
                      _CategoryStatistics(
                        title: '수입 분류',
                        transactions: current
                            .where(
                              (item) => item.type == TransactionType.income,
                            )
                            .toList(),
                        color: AppColors.mint,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatSummaryCard extends StatelessWidget {
  const _StatSummaryCard({
    required this.label,
    required this.amount,
    required this.previousAmount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final int previousAmount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final change = percentageChange(amount, previousAmount);
    final isIncrease = amount >= previousAmount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, color, 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${formatWon(amount)}원',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            change,
            style: TextStyle(
              color: amount == previousAmount
                  ? const Color(0xFF6B7280)
                  : isIncrease
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF2563EB),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE9F2), Color(0xFFF1EBFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          const Text('이번 달 잔액', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            '${formatWon(balance)}원',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CategoryStatistics extends StatelessWidget {
  const _CategoryStatistics({
    required this.title,
    required this.transactions,
    required this.color,
  });

  final String title;
  final List<BudgetTransaction> transactions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <String, int>{};
    for (final transaction in transactions) {
      categoryTotals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (value, item) => value + item.value);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FA64D72),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  '이 달에는 내역이 없어요.',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            ...entries.map((entry) {
              final ratio = total == 0 ? 0.0 : entry.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(categoryIcon(entry.key), size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${formatWon(entry.value)}원',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${(ratio * 100).round()}%',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 7,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.showDate = true,
    this.onTap,
  });

  final BudgetTransaction transaction;
  final bool showDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = transaction.isRefund
        ? AppColors.lavender
        : isExpense
        ? AppColors.coral
        : AppColors.mint;
    final icon = categoryIcon(transaction.category);

    return Card(
      clipBehavior: Clip.antiAlias,
      color: Color.lerp(Colors.white, color, 0.025),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.13)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.16),
                      color.withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        transaction.category,
                        if (showDate) formatDate(transaction.date),
                        if (transaction.sourceApp.isNotEmpty)
                          transaction.sourceApp,
                      ].join(' · '),
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.isRefund || !isExpense ? '+' : '-'}'
                    '${formatWon(transaction.amount)}원',
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 3),
                    const Text(
                      '눌러서 관리',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 46, color: Color(0xFFF0A1BE)),
          SizedBox(height: 12),
          Text('아직 거래가 없어요', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            '아래 버튼으로 첫 내역을 추가해보세요.',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class CategoryManagerPage extends StatefulWidget {
  const CategoryManagerPage({
    super.key,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.categoryIcons,
    required this.onSave,
  });

  final List<String> expenseCategories;
  final List<String> incomeCategories;
  final Map<String, String> categoryIcons;
  final Future<void> Function({
    required List<String> expenses,
    required List<String> incomes,
    required Map<String, String> icons,
  })
  onSave;

  @override
  State<CategoryManagerPage> createState() => _CategoryManagerPageState();
}

class _CategoryManagerPageState extends State<CategoryManagerPage> {
  final _controller = TextEditingController();
  late List<String> _expenses;
  late List<String> _incomes;
  late Map<String, String> _icons;
  String _newCategoryIconKey = 'more';
  TransactionType _selectedType = TransactionType.expense;
  bool _saving = false;

  List<String> get _selectedCategories {
    return _selectedType == TransactionType.expense ? _expenses : _incomes;
  }

  @override
  void initState() {
    super.initState();
    _expenses = [...widget.expenseCategories];
    _incomes = [...widget.incomeCategories];
    _icons = {...defaultCategoryIconKeys, ...widget.categoryIcons};
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addCategory() {
    final category = _controller.text.trim();
    if (category.isEmpty) {
      return;
    }
    if (_selectedCategories.contains(category)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 있는 분류입니다.')));
      return;
    }
    setState(() {
      _selectedCategories.add(category);
      _icons[category] = _newCategoryIconKey;
      _controller.clear();
      _newCategoryIconKey = 'more';
    });
  }

  void _removeCategory(String category) {
    if (_selectedCategories.length == 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('분류를 한 개 이상 남겨주세요.')));
      return;
    }
    setState(() {
      _selectedCategories.remove(category);
      if (!_expenses.contains(category) && !_incomes.contains(category)) {
        _icons.remove(category);
      }
    });
  }

  Future<void> _pickIcon({String? category}) async {
    final currentKey = category == null
        ? _newCategoryIconKey
        : _icons[category] ?? defaultCategoryIconKeys[category] ?? 'more';
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(category == null ? '새 분류 아이콘' : '$category 아이콘'),
        content: SizedBox(
          width: 320,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: categoryIconChoices.entries.map((entry) {
              final isSelected = entry.key == currentKey;
              return InkWell(
                onTap: () => Navigator.of(dialogContext).pop(entry.key),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Icon(
                    entry.value,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF4B5563),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        if (category == null) {
          _newCategoryIconKey = selected;
        } else {
          _icons[category] = selected;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(
        expenses: _expenses,
        incomes: _incomes,
        icons: _icons,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_firestoreErrorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '분류 관리',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SoftPastelBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('지출 분류'),
                      icon: Icon(Icons.north_east_rounded),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('수입 분류'),
                      icon: Icon(Icons.south_west_rounded),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedType = selection.first;
                      _controller.clear();
                    });
                  },
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => _pickIcon(),
                      icon: Icon(
                        categoryIconChoices[_newCategoryIconKey] ??
                            Icons.more_horiz_rounded,
                      ),
                      tooltip: '새 분류 아이콘 선택',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addCategory(),
                        decoration: const InputDecoration(
                          hintText: '새 분류 이름',
                          prefixIcon: Icon(Icons.add_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _addCategory,
                        child: const Text('추가'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  '${_selectedCategories.length}개 분류',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: _selectedCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = _selectedCategories[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: IconButton.filledTonal(
                            onPressed: () => _pickIcon(category: category),
                            icon: Icon(categoryIcon(category, _icons)),
                            tooltip: '아이콘 변경',
                          ),
                          title: Text(
                            category,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: IconButton(
                            onPressed: () => _removeCategory(category),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: '삭제',
                          ),
                        ),
                      );
                    },
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

class TrashPage extends StatefulWidget {
  const TrashPage({
    super.key,
    required this.transactions,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  final List<BudgetTransaction> transactions;
  final Future<void> Function(BudgetTransaction) onRestore;
  final Future<void> Function(BudgetTransaction) onDeletePermanently;

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  late final List<BudgetTransaction> _items;
  final Set<String> _workingIds = {};

  @override
  void initState() {
    super.initState();
    _items = [...widget.transactions]
      ..sort(
        (first, second) => (second.deletedAt ?? second.date).compareTo(
          first.deletedAt ?? first.date,
        ),
      );
  }

  Future<void> _restore(BudgetTransaction transaction) async {
    setState(() => _workingIds.add(transaction.id));
    try {
      await widget.onRestore(transaction);
      if (mounted) {
        setState(() => _items.removeWhere((item) => item.id == transaction.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복원하지 못했습니다. 인터넷 연결을 확인해 주세요.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _workingIds.remove(transaction.id));
      }
    }
  }

  Future<void> _deletePermanently(BudgetTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('완전히 삭제할까요?'),
        content: Text(
          '${transaction.title} · ${formatWon(transaction.amount)}원\n'
          '완전히 삭제하면 다시 복원할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42335),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('완전 삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _workingIds.add(transaction.id));
    try {
      await widget.onDeletePermanently(transaction);
      if (mounted) {
        setState(() => _items.removeWhere((item) => item.id == transaction.id));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('완전히 삭제하지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _workingIds.remove(transaction.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('휴지통')),
      body: SoftPastelBackground(
        child: _items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_sweep_outlined,
                      size: 54,
                      color: Color(0xFFB8A9B1),
                    ),
                    SizedBox(height: 12),
                    Text('휴지통이 비어 있어요.'),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final transaction = _items[index];
                  final working = _workingIds.contains(transaction.id);
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(categoryIcon(transaction.category)),
                      ),
                      title: Text(
                        transaction.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${formatWon(transaction.amount)}원 · ${formatDate(transaction.date)}',
                      ),
                      trailing: working
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'restore') {
                                  _restore(transaction);
                                } else {
                                  _deletePermanently(transaction);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'restore',
                                  child: ListTile(
                                    leading: Icon(Icons.restore_rounded),
                                    title: Text('복원하기'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_forever_rounded,
                                      color: Color(0xFFB42335),
                                    ),
                                    title: Text(
                                      '완전히 삭제',
                                      style: TextStyle(
                                        color: Color(0xFFB42335),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class AppPinUnlockPage extends StatefulWidget {
  const AppPinUnlockPage({
    super.key,
    required this.onUnlocked,
    required this.biometricEnabled,
  });

  final VoidCallback onUnlocked;
  final bool biometricEnabled;

  @override
  State<AppPinUnlockPage> createState() => _AppPinUnlockPageState();
}

class _AppPinUnlockPageState extends State<AppPinUnlockPage> {
  final _controller = TextEditingController();
  bool _checking = false;
  String? _error;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    if (widget.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useBiometric());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_controller.text.length != 4 || _checking || _isTemporarilyLocked) {
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final verified = await AppSettingsService.verifyAppPin(_controller.text);
    if (!mounted) return;
    if (verified) {
      widget.onUnlocked();
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
        _lockTimer?.cancel();
        _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          if (!_isTemporarilyLocked) {
            timer.cancel();
            setState(() {
              _failedAttempts = 0;
              _lockedUntil = null;
              _error = null;
            });
          } else {
            setState(() {});
          }
        });
      }
      setState(() {
        _checking = false;
        _error = _isTemporarilyLocked
            ? '입력 횟수가 많아요. 30초 후 다시 시도해 주세요.'
            : 'PIN 번호가 맞지 않습니다. (${5 - _failedAttempts}회 남음)';
        _controller.clear();
      });
    }
  }

  bool get _isTemporarilyLocked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  int get _remainingLockSeconds {
    if (!_isTemporarilyLocked) return 0;
    return _lockedUntil!.difference(DateTime.now()).inSeconds + 1;
  }

  Future<void> _useBiometric() async {
    if (_checking || _isTemporarilyLocked) return;
    final verified = await AppSettingsService.authenticateBiometric();
    if (verified && mounted) widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftPastelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(28),
                decoration: softCardDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: appGradient,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '가계부 잠금',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      '4자리 PIN 번호를 입력해 주세요.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      obscureText: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        letterSpacing: 14,
                        fontWeight: FontWeight.w900,
                      ),
                      onChanged: (_) {
                        if (_controller.text.length == 4) _unlock();
                      },
                      onSubmitted: (_) => _unlock(),
                      decoration: const InputDecoration(counterText: ''),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.coral),
                      ),
                    ],
                    if (_isTemporarilyLocked)
                      Text(
                        '$_remainingLockSeconds초 남음',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    if (widget.biometricEnabled) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _isTemporarilyLocked ? null : _useBiometric,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('지문·얼굴로 열기'),
                      ),
                    ],
                    if (_checking) ...[
                      const SizedBox(height: 14),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({
    super.key,
    required this.monthlyBudget,
    required this.categoryBudgets,
    required this.monthlySavingsGoal,
    required this.recurringRules,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.onSaveAutomation,
    required this.onExportCsv,
    required this.onExportCsvRange,
    required this.onImportCsv,
    required this.onExportFullBackup,
    required this.onImportFullBackup,
    required this.onLockChanged,
    required this.onBiometricChanged,
  });

  final int monthlyBudget;
  final Map<String, int> categoryBudgets;
  final int monthlySavingsGoal;
  final List<RecurringTransactionRule> recurringRules;
  final List<String> expenseCategories;
  final List<String> incomeCategories;
  final Future<void> Function({
    required int monthlyBudget,
    required Map<String, int> categoryBudgets,
    required int monthlySavingsGoal,
    required List<RecurringTransactionRule> recurringRules,
  })
  onSaveAutomation;
  final Future<void> Function() onExportCsv;
  final Future<void> Function() onExportCsvRange;
  final Future<void> Function() onImportCsv;
  final Future<void> Function() onExportFullBackup;
  final Future<void> Function() onImportFullBackup;
  final ValueChanged<bool> onLockChanged;
  final ValueChanged<bool> onBiometricChanged;

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  late final TextEditingController _budgetController;
  late final TextEditingController _savingsGoalController;
  late Map<String, int> _categoryBudgets;
  late List<RecurringTransactionRule> _rules;
  List<NotificationAppOption> _notificationApps = [];
  bool _loadingApps = true;
  bool _pinEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController(
      text: widget.monthlyBudget > 0 ? formatWon(widget.monthlyBudget) : '',
    );
    _savingsGoalController = TextEditingController(
      text: widget.monthlySavingsGoal > 0
          ? formatWon(widget.monthlySavingsGoal)
          : '',
    );
    _categoryBudgets = {...widget.categoryBudgets};
    _rules = [...widget.recurringRules];
    _loadDeviceSettings();
  }

  Future<void> _loadDeviceSettings() async {
    try {
      final results = await Future.wait([
        AppSettingsService.getObservedNotificationApps(),
        AppSettingsService.hasAppPin(),
        AppSettingsService.hasBiometric(),
        AppSettingsService.getBiometricEnabled(),
      ]);
      if (mounted) {
        setState(() {
          _notificationApps = results[0] as List<NotificationAppOption>;
          _pinEnabled = results[1] as bool;
          _biometricAvailable = results[2] as bool;
          _biometricEnabled = results[3] as bool;
          _loadingApps = false;
        });
      }
    } on MissingPluginException {
      if (mounted) setState(() => _loadingApps = false);
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  Future<void> _addRecurringRule() async {
    final transaction = await showModalBottomSheet<BudgetTransaction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        expenseCategories: widget.expenseCategories,
        incomeCategories: widget.incomeCategories,
      ),
    );
    if (transaction == null || !mounted) return;
    var cycle = RepeatCycle.monthly;
    var confirmBeforeAdding = false;
    var variableAmount = false;
    DateTime? endDate;
    final configured = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('반복 방법 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<RepeatCycle>(
                initialValue: cycle,
                decoration: const InputDecoration(labelText: '반복 주기'),
                items: RepeatCycle.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => cycle = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: confirmBeforeAdding,
                onChanged: (value) =>
                    setDialogState(() => confirmBeforeAdding = value),
                title: const Text('등록 전 확인'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: variableAmount,
                onChanged: (value) =>
                    setDialogState(() => variableAmount = value),
                title: const Text('매번 금액이 달라요'),
                subtitle: const Text('등록할 때 금액을 확인합니다.'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('반복 종료일'),
                subtitle: Text(
                  endDate == null ? '종료일 없음' : formatFullDate(endDate!),
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate:
                        endDate ??
                        DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (selected != null) {
                    setDialogState(() => endDate = selected);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
    if (configured != true || !mounted) return;
    setState(() {
      _rules.add(
        RecurringTransactionRule(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: transaction.title,
          category: transaction.category,
          amount: transaction.amount,
          type: transaction.type,
          day: transaction.date.day,
          month: transaction.date.month,
          weekday: transaction.date.weekday,
          memo: transaction.memo,
          cycle: cycle,
          endDate: endDate,
          confirmBeforeAdding: confirmBeforeAdding || variableAmount,
          variableAmount: variableAmount,
        ),
      );
    });
  }

  Future<String?> _showPinDialog({required bool creating}) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(creating ? '4자리 PIN 만들기' : '현재 PIN 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                autofocus: true,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'PIN 번호',
                  counterText: '',
                ),
              ),
              if (creating) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'PIN 번호 확인',
                    counterText: '',
                  ),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: AppColors.coral)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final value = pinController.text;
                if (value.length != 4) {
                  setDialogState(() => error = '4자리 숫자를 입력해 주세요.');
                } else if (creating && value != confirmController.text) {
                  setDialogState(() => error = 'PIN 번호가 서로 다릅니다.');
                } else {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
    disposeControllerAfterDialog(pinController);
    disposeControllerAfterDialog(confirmController);
    return pin;
  }

  Future<void> _togglePin(bool enabled) async {
    final pin = await _showPinDialog(creating: enabled);
    if (pin == null) return;
    if (enabled) {
      await AppSettingsService.setAppPin(pin);
    } else {
      final verified = await AppSettingsService.verifyAppPin(pin);
      if (!verified) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PIN 번호가 맞지 않습니다.')));
        }
        return;
      }
      await AppSettingsService.removeAppPin();
    }
    if (mounted) {
      setState(() => _pinEnabled = enabled);
      widget.onLockChanged(enabled);
      if (!enabled) {
        setState(() => _biometricEnabled = false);
        widget.onBiometricChanged(false);
      }
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (!_pinEnabled) return;
    if (enabled) {
      final verified = await AppSettingsService.authenticateBiometric();
      if (!verified) return;
    }
    await AppSettingsService.setBiometricEnabled(enabled);
    if (mounted) {
      setState(() => _biometricEnabled = enabled);
      widget.onBiometricChanged(enabled);
    }
  }

  Future<void> _toggleNotificationApp(int index, bool selected) async {
    setState(() {
      final item = _notificationApps[index];
      _notificationApps[index] = NotificationAppOption(
        packageName: item.packageName,
        label: item.label,
        selected: selected,
      );
    });
    final selectedPackages = _notificationApps
        .where((item) => item.selected)
        .map((item) => item.packageName)
        .toList();
    await AppSettingsService.setSelectedNotificationApps(selectedPackages);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSaveAutomation(
        monthlyBudget:
            int.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0,
        categoryBudgets: {
          for (final entry in _categoryBudgets.entries)
            if (entry.value > 0) entry.key: entry.value,
        },
        monthlySavingsGoal:
            int.tryParse(_savingsGoalController.text.replaceAll(',', '')) ?? 0,
        recurringRules: _rules,
      );
      if (mounted) Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_firestoreErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: softCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '생활 설정',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SoftPastelBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _section(
              title: '테마 색상',
              icon: Icons.palette_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  children: AppThemeChoice.values.map((choice) {
                    return ChoiceChip(
                      selected: appThemeChoice.value == choice,
                      avatar: CircleAvatar(backgroundColor: choice.color),
                      label: Text(choice.label),
                      onSelected: (_) async {
                        await AppSettingsService.setThemeChoice(choice);
                        if (mounted) setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _section(
              title: '월 예산',
              icon: Icons.savings_outlined,
              children: [
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [WonAmountInputFormatter()],
                  decoration: const InputDecoration(
                    hintText: '예: 1,500,000',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '예산에 도달하면 앱 알림과 홈 카드로 알려드려요.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _section(
              title: '분류별 예산과 저축 목표',
              icon: Icons.track_changes_rounded,
              children: [
                TextField(
                  controller: _savingsGoalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [WonAmountInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: '이번 달 저축 목표',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.expenseCategories
                    .where((category) => category != '환불')
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          initialValue: _categoryBudgets[category] == null
                              ? ''
                              : formatWon(_categoryBudgets[category]!),
                          keyboardType: TextInputType.number,
                          inputFormatters: [WonAmountInputFormatter()],
                          onChanged: (value) {
                            _categoryBudgets[category] =
                                int.tryParse(value.replaceAll(',', '')) ?? 0;
                          },
                          decoration: InputDecoration(
                            labelText: '$category 예산',
                            prefixIcon: Icon(categoryIcon(category)),
                            suffixText: '원',
                          ),
                        ),
                      ),
                    ),
                const Text(
                  '홈에서 하루 권장 지출, 월말 예상 지출과 분류별 사용량을 보여드려요.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _section(
              title: '반복 내역',
              icon: Icons.event_repeat_rounded,
              children: [
                if (_rules.isEmpty)
                  const Text(
                    '월세·보험·구독료처럼 매달 반복되는 내역을 등록해 보세요.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ..._rules.asMap().entries.map((entry) {
                  final index = entry.key;
                  final rule = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      value: rule.enabled,
                      onChanged: (enabled) {
                        setState(() {
                          _rules[index] = RecurringTransactionRule(
                            id: rule.id,
                            title: rule.title,
                            category: rule.category,
                            amount: rule.amount,
                            type: rule.type,
                            day: rule.day,
                            memo: rule.memo,
                            enabled: enabled,
                            cycle: rule.cycle,
                            month: rule.month,
                            weekday: rule.weekday,
                            endDate: rule.endDate,
                            confirmBeforeAdding: rule.confirmBeforeAdding,
                            variableAmount: rule.variableAmount,
                          );
                        });
                      },
                      title: Text(
                        rule.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${rule.cycle.label} '
                        '${rule.cycle == RepeatCycle.weekly
                            ? '${const ['월', '화', '수', '목', '금', '토', '일'][rule.weekday - 1]}요일'
                            : rule.cycle == RepeatCycle.yearly
                            ? '${rule.month}/${rule.day}'
                            : '${rule.day}일'}'
                        ' · ${formatWon(rule.amount)}원 · ${rule.category}'
                        '${rule.confirmBeforeAdding ? ' · 확인 후 등록' : ''}',
                      ),
                      secondary: IconButton(
                        onPressed: () => setState(() => _rules.removeAt(index)),
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: '삭제',
                      ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _addRecurringRule,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('반복 내역 추가'),
                ),
                const SizedBox(height: 5),
                const Text(
                  '추가 화면의 날짜에서 매월 자동등록할 날짜를 선택하세요.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _section(
              title: '자동인식 앱 선택',
              icon: Icons.notifications_active_outlined,
              children: [
                if (_loadingApps)
                  const Center(child: CircularProgressIndicator())
                else if (_notificationApps.isEmpty)
                  const Text(
                    '결제 Push를 한 번 받은 뒤 다시 열면 은행·카드 앱 목록이 표시됩니다. SMS는 항상 인식합니다.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  )
                else
                  ..._notificationApps.asMap().entries.map((entry) {
                    final item = entry.value;
                    return CheckboxListTile(
                      value: item.selected,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.label),
                      subtitle: Text(
                        item.packageName,
                        style: const TextStyle(fontSize: 10),
                      ),
                      onChanged: (value) =>
                          _toggleNotificationApp(entry.key, value ?? false),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 12),
            _section(
              title: '앱 잠금',
              icon: Icons.lock_outline_rounded,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _pinEnabled,
                  onChanged: _togglePin,
                  title: const Text('4자리 PIN 잠금'),
                  subtitle: const Text('앱을 다시 열 때 가계부를 보호합니다.'),
                ),
                if (_biometricAvailable)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _biometricEnabled && _pinEnabled,
                    onChanged: _pinEnabled ? _toggleBiometric : null,
                    title: const Text('지문·얼굴로 잠금 해제'),
                    subtitle: const Text('PIN을 먼저 설정한 후 사용할 수 있어요.'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _section(
              title: '파일 백업과 복원',
              icon: Icons.folder_copy_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onExportCsv,
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('파일 내보내기'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onImportCsv,
                        icon: const Icon(Icons.file_upload_outlined),
                        label: const Text('파일 가져오기'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onExportCsvRange,
                        icon: const Icon(Icons.date_range_rounded),
                        label: const Text('기간 선택 CSV'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onExportFullBackup,
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('전체 백업'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: widget.onImportFullBackup,
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  label: const Text('전체 백업 파일 복원'),
                ),
                const SizedBox(height: 7),
                const Text(
                  '파일 선택 화면에서 Google Drive를 고르면 Drive에 바로 저장할 수 있어요.',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _section(
              title: '홈 화면 위젯',
              icon: Icons.widgets_outlined,
              children: const [
                Text(
                  '휴대폰 홈 화면을 길게 누른 뒤 위젯 → 모아봄을 선택하면 이번 달 지출과 남은 예산을 볼 수 있어요.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TogetherPage extends StatefulWidget {
  const TogetherPage({
    super.key,
    required this.user,
    required this.onManageCategories,
    required this.onOpenTrash,
    required this.onCopyCsvBackup,
    required this.onOpenAdvancedSettings,
    required this.availableLedgers,
    required this.onSelectLedger,
    required this.onImportPersonalTransactions,
    required this.ledgerId,
    required this.ledgerName,
    required this.memberEmails,
    required this.memberIds,
    required this.transactions,
    required this.currentUserId,
    required this.ledgerColorKey,
    required this.onUpdateLedgerAppearance,
  });

  final User user;
  final VoidCallback onManageCategories;
  final VoidCallback onOpenTrash;
  final VoidCallback onCopyCsvBackup;
  final VoidCallback onOpenAdvancedSettings;
  final List<LedgerOption> availableLedgers;
  final ValueChanged<String> onSelectLedger;
  final Future<int> Function() onImportPersonalTransactions;
  final String ledgerId;
  final String ledgerName;
  final List<String> memberEmails;
  final List<String> memberIds;
  final List<BudgetTransaction> transactions;
  final String currentUserId;
  final String ledgerColorKey;
  final Future<void> Function(String name, String colorKey)
  onUpdateLedgerAppearance;

  @override
  State<TogetherPage> createState() => _TogetherPageState();
}

class _TogetherPageState extends State<TogetherPage> {
  bool _isWorking = false;
  bool _isImporting = false;

  bool get _isShared => widget.ledgerId.startsWith('shared_');
  bool get _hasSharedLedger =>
      widget.availableLedgers.any((ledger) => ledger.isShared);
  String get _inviteCode => widget.user.uid.substring(0, 8).toUpperCase();

  Future<void> _editLedgerAppearance() async {
    final controller = TextEditingController(text: widget.ledgerName);
    var colorKey = widget.ledgerColorKey;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('공동 가계부 꾸미기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLength: 30,
                decoration: const InputDecoration(labelText: '가계부 이름'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 9,
                children: AppThemeChoice.values.map((choice) {
                  return ChoiceChip(
                    selected: colorKey == choice.name,
                    avatar: CircleAvatar(backgroundColor: choice.color),
                    label: Text(choice.label),
                    onSelected: (_) =>
                        setDialogState(() => colorKey = choice.name),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    final name = controller.text;
    disposeControllerAfterDialog(controller);
    if (saved != true || name.trim().isEmpty) return;
    try {
      await widget.onUpdateLedgerAppearance(name, colorKey);
      _showMessage('공동 가계부를 예쁘게 꾸몄어요.');
    } on FirebaseException catch (error) {
      _showMessage(_firestoreErrorMessage(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('현재 계정에서 로그아웃할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _importPersonalTransactions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('개인 내역을 가져올까요?'),
        content: const Text(
          '개인 가계부의 내역을 현재 공동 가계부로 복사합니다.\n\n'
          '개인 가계부의 원본은 그대로 남으며, 같은 내역을 다시 가져와도 '
          '중복 문서가 생성되지 않습니다.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('가져오기'),
          ),
        ],
      ),
    );
    if (confirmed != true || _isImporting) {
      return;
    }

    setState(() => _isImporting = true);
    try {
      final count = await widget.onImportPersonalTransactions();
      _showMessage(
        count == 0 ? '개인 가계부에 가져올 내역이 없습니다.' : '개인 내역 $count건을 가져왔습니다.',
      );
    } on FirebaseException catch (error) {
      _showMessage(_firestoreErrorMessage(error));
    } on TimeoutException {
      _showMessage('내역 가져오기 시간이 초과되었습니다. 인터넷을 확인해 주세요.');
    } on StateError catch (error) {
      _showMessage(error.message.toString());
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _openInviteDialog() async {
    if (_isShared || _isWorking) {
      return;
    }

    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('초대 코드 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          decoration: const InputDecoration(
            hintText: '예: 7ALDDPRJ',
            prefixIcon: Icon(Icons.key_rounded),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: const Text('요청 보내기'),
          ),
        ],
      ),
    );
    disposeControllerAfterDialog(controller);

    if (code != null) {
      await _sendInvitation(code);
    }
  }

  Future<void> _sendInvitation(String rawCode) async {
    final code = rawCode.replaceAll(' ', '').toUpperCase();
    if (code == _inviteCode) {
      _showMessage('내 초대 코드는 입력할 수 없습니다.');
      return;
    }
    if (code.length != 8) {
      _showMessage('8자리 초대 코드를 확인해 주세요.');
      return;
    }

    setState(() => _isWorking = true);
    try {
      final database = FirebaseFirestore.instance;
      final targetSnapshot = await database
          .collection('inviteCodes')
          .doc(code)
          .get();
      final targetData = targetSnapshot.data();
      final receiverId = targetData?['userId'] as String?;
      final receiverEmail = targetData?['email'] as String?;

      if (receiverId == null || receiverId.isEmpty) {
        _showMessage('해당 초대 코드를 찾을 수 없습니다.');
        return;
      }
      if (receiverId == widget.user.uid) {
        _showMessage('내 초대 코드는 입력할 수 없습니다.');
        return;
      }

      final invitations = database.collection('invitations');
      final snapshots = await Future.wait([
        invitations.where('senderId', isEqualTo: widget.user.uid).get(),
        invitations.where('receiverId', isEqualTo: widget.user.uid).get(),
      ]);
      final hasPendingRequest = snapshots
          .expand((snapshot) => snapshot.docs)
          .any((document) {
            final data = document.data();
            final isSamePair =
                (data['senderId'] == widget.user.uid &&
                    data['receiverId'] == receiverId) ||
                (data['senderId'] == receiverId &&
                    data['receiverId'] == widget.user.uid);
            return isSamePair && data['status'] == 'pending';
          });
      if (hasPendingRequest) {
        _showMessage('이미 두 사람 사이에 대기 중인 요청이 있습니다.');
        return;
      }

      await invitations.add({
        'senderId': widget.user.uid,
        'senderEmail': widget.user.email,
        'senderInviteCode': _inviteCode,
        'receiverId': receiverId,
        'receiverEmail': receiverEmail,
        'receiverInviteCode': code,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _showMessage('함께쓰기 요청을 보냈습니다.');
    } on FirebaseException catch (error) {
      debugPrint('Invitation send failed: ${error.code} ${error.message}');
      _showMessage(_firestoreErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  Future<void> _respondToInvitation(
    QueryDocumentSnapshot<Map<String, dynamic>> invitation, {
    required bool accept,
  }) async {
    if (_isWorking || (accept && _isShared)) {
      return;
    }

    setState(() => _isWorking = true);
    try {
      final data = invitation.data();
      final senderId = data['senderId'] as String? ?? '';
      final receiverId = data['receiverId'] as String? ?? '';
      final senderEmail = data['senderEmail'] as String? ?? '초대한 사람';
      final receiverEmail =
          data['receiverEmail'] as String? ?? widget.user.email ?? '나';
      if (receiverId != widget.user.uid ||
          senderId.isEmpty ||
          data['status'] != 'pending') {
        _showMessage('이미 처리되었거나 올바르지 않은 요청입니다.');
        return;
      }

      final database = FirebaseFirestore.instance;
      if (!accept) {
        await invitation.reference.update({
          'status': 'rejected',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        _showMessage('요청을 거절했습니다.');
        return;
      }

      final sharedLedgerId = 'shared_${invitation.id}';
      final batch = database.batch();
      batch.set(database.collection('ledgers').doc(sharedLedgerId), {
        'name': '함께 쓰는 가계부',
        'memberIds': [senderId, receiverId],
        'memberEmails': [senderEmail, receiverEmail],
        'createdBy': senderId,
        'acceptedBy': receiverId,
        'sourceInvitationId': invitation.id,
        'expenseCategories': defaultExpenseCategories,
        'incomeCategories': defaultIncomeCategories,
        'categoryIcons': defaultCategoryIconKeys,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(invitation.reference, {
        'status': 'accepted',
        'sharedLedgerId': sharedLedgerId,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      _showMessage('연결되었습니다. 이제 두 사람이 같은 가계부를 사용합니다.');
    } on FirebaseException catch (error) {
      debugPrint('Invitation response failed: ${error.code} ${error.message}');
      _showMessage(_firestoreErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortInvitations(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final result = documents.toList();
    result.sort((a, b) {
      final aDate = a.data()['createdAt'];
      final bDate = b.data()['createdAt'];
      final aMilliseconds = aDate is Timestamp
          ? aDate.millisecondsSinceEpoch
          : 0;
      final bMilliseconds = bDate is Timestamp
          ? bDate.millisecondsSinceEpoch
          : 0;
      return bMilliseconds.compareTo(aMilliseconds);
    });
    return result;
  }

  Widget _buildIncomingInvitations(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('invitations')
          .where('receiverId', isEqualTo: widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _TogetherNotice(
            icon: Icons.error_outline_rounded,
            text: '받은 요청을 불러오지 못했습니다.',
          );
        }
        final invitations = _sortInvitations(
          snapshot.data?.docs.where(
                (document) => document.data()['status'] == 'pending',
              ) ??
              const [],
        );
        if (invitations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '받은 요청',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...invitations.map((invitation) {
              final senderEmail =
                  invitation.data()['senderEmail'] as String? ?? '사용자';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderEmail,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '함께 가계부를 사용하고 싶어 합니다.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isWorking
                                ? null
                                : () => _respondToInvitation(
                                    invitation,
                                    accept: false,
                                  ),
                            child: const Text('거절'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _isWorking || _isShared
                                ? null
                                : () => _respondToInvitation(
                                    invitation,
                                    accept: true,
                                  ),
                            child: const Text('수락'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildSentInvitations(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('invitations')
          .where('senderId', isEqualTo: widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _TogetherNotice(
            icon: Icons.error_outline_rounded,
            text: '보낸 요청을 불러오지 못했습니다.',
          );
        }
        final invitations = _sortInvitations(snapshot.data?.docs ?? const []);
        if (invitations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '보낸 요청',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            ...invitations.take(5).map((invitation) {
              final data = invitation.data();
              final receiverEmail = data['receiverEmail'] as String? ?? '사용자';
              final status = data['status'] as String? ?? 'pending';
              final statusText = switch (status) {
                'accepted' => '수락됨',
                'rejected' => '거절됨',
                _ => '승인 기다리는 중',
              };
              final statusColor = switch (status) {
                'accepted' => const Color(0xFF047857),
                'rejected' => const Color(0xFFB91C1C),
                _ => const Color(0xFF6B7280),
              };
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline_rounded),
                  ),
                  title: Text(
                    receiverEmail,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnerEmails = widget.memberEmails
        .where((email) => email != widget.user.email)
        .toList();
    final partnerName = partnerEmails.isEmpty
        ? '상대방'
        : partnerEmails.join(', ');
    final ledgerAccent = AppThemeChoice.values
        .firstWhere(
          (choice) => choice.name == widget.ledgerColorKey,
          orElse: () => AppThemeChoice.pink,
        )
        .color;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '함께쓰기',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: () => _confirmSignOut(context),
                    color: AppColors.deepRose,
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: '로그아웃',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '가족이나 연인을 초대해 같은 가계부를 사용할 수 있어요.',
              style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: softCardDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.availableLedgers.isNotEmpty) ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '사용할 가계부',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          DropdownButtonFormField<String>(
                            key: ValueKey(widget.ledgerId),
                            initialValue:
                                widget.availableLedgers.any(
                                  (ledger) => ledger.id == widget.ledgerId,
                                )
                                ? widget.ledgerId
                                : null,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.swap_horiz_rounded),
                            ),
                            items: widget.availableLedgers.map((ledger) {
                              final partners = ledger.memberEmails
                                  .where((email) => email != widget.user.email)
                                  .join(', ');
                              final label = ledger.isShared
                                  ? '${ledger.name}${partners.isEmpty ? '' : ' · $partners'}'
                                  : '내 개인 가계부';
                              return DropdownMenuItem(
                                value: ledger.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      ledger.isShared
                                          ? Icons.people_rounded
                                          : Icons.person_rounded,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 9),
                                    Flexible(
                                      child: Text(
                                        label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (ledgerId) {
                              if (ledgerId != null) {
                                widget.onSelectLedger(ledgerId);
                              }
                            },
                          ),
                          const SizedBox(height: 28),
                        ],
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: _isShared
                                ? LinearGradient(
                                    colors: [
                                      ledgerAccent,
                                      Color.lerp(
                                        ledgerAccent,
                                        Colors.white,
                                        0.24,
                                      )!,
                                    ],
                                  )
                                : appGradient,
                            borderRadius: BorderRadius.circular(27),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x30E85D93),
                                blurRadius: 22,
                                offset: Offset(0, 9),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isShared
                                ? Icons.people_rounded
                                : _hasSharedLedger
                                ? Icons.person_rounded
                                : Icons.group_add_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isShared
                              ? '공동 가계부 연결 완료'
                              : _hasSharedLedger
                              ? '개인 가계부 사용 중'
                              : '함께할 사람을 초대해요',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isShared
                              ? '$partnerName 님과 같은 내역을 보고 있어요.'
                              : _hasSharedLedger
                              ? '위 메뉴에서 개인 가계부와 공동 가계부를 전환할 수 있어요.'
                              : '상대방의 초대 코드를 입력하면\n승인 요청이 전송됩니다.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        if (_isShared) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.ledgerName,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              IconButton(
                                onPressed: _editLedgerAppearance,
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                tooltip: '이름과 색상 변경',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SharedSettlementCard(
                            transactions: widget.transactions,
                            currentUserId: widget.currentUserId,
                            memberIds: widget.memberIds,
                            memberEmails: widget.memberEmails,
                          ),
                          const SizedBox(height: 14),
                          FilledButton.tonalIcon(
                            onPressed: _isImporting
                                ? null
                                : _importPersonalTransactions,
                            icon: _isImporting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download_rounded),
                            label: Text(
                              _isImporting ? '가져오는 중...' : '기존 개인 내역 가져오기',
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.only(
                            left: 16,
                            top: 8,
                            right: 8,
                            bottom: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.key_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '내 코드: $_inviteCode',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: _inviteCode),
                                  );
                                  _showMessage('초대 코드를 복사했습니다.');
                                },
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('공유'),
                              ),
                            ],
                          ),
                        ),
                        if (!_isShared) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _isWorking ? null : _openInviteDialog,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(_isWorking ? '처리 중...' : '초대 코드 입력'),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildIncomingInvitations(context),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _buildSentInvitations(context),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: widget.onManageCategories,
                              icon: const Icon(Icons.category_outlined),
                              label: const Text('분류 관리'),
                            ),
                            OutlinedButton.icon(
                              onPressed: widget.onOpenTrash,
                              icon: const Icon(
                                Icons.restore_from_trash_rounded,
                              ),
                              label: const Text('휴지통'),
                            ),
                            OutlinedButton.icon(
                              onPressed: widget.onCopyCsvBackup,
                              icon: const Icon(Icons.table_view_rounded),
                              label: const Text('CSV 백업 복사'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: widget.onOpenAdvancedSettings,
                              icon: const Icon(Icons.tune_rounded),
                              label: const Text('생활 설정'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2ECFF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFDCCFFF)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.school_rounded,
                                color: Color(0xFF7D62C8),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '무료 자동분류',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '자동 인식 내역을 수정해 저장하면 '
                                      '다음에 같은 사용처의 분류를 자동으로 '
                                      '맞춰요. 외부 AI로 전송하지 않아요.',
                                      style: TextStyle(
                                        color: Color(0xFF624AA8),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.user.email ?? '사용자',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SharedSettlementCard extends StatelessWidget {
  const SharedSettlementCard({
    super.key,
    required this.transactions,
    required this.currentUserId,
    required this.memberIds,
    required this.memberEmails,
  });

  final List<BudgetTransaction> transactions;
  final String currentUserId;
  final List<String> memberIds;
  final List<String> memberEmails;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = transactions.where(
      (item) =>
          isSameMonth(item.date, now) && item.type == TransactionType.expense,
    );
    var mine = 0;
    var partner = 0;
    for (final item in current) {
      final signedAmount = item.isRefund ? -item.amount : item.amount;
      if (item.createdBy == currentUserId || item.createdBy.isEmpty) {
        mine += signedAmount;
      } else {
        partner += signedAmount;
      }
    }
    final difference = (mine - partner).abs();
    final settlement = (difference / 2).round();
    final partnerIndex = memberIds.indexWhere((id) => id != currentUserId);
    final partnerName = partnerIndex >= 0 && partnerIndex < memberEmails.length
        ? memberEmails[partnerIndex].split('@').first
        : '상대방';
    final settlementText = difference < 100
        ? '이번 달은 거의 똑같이 부담했어요.'
        : mine > partner
        ? '$partnerName 님이 나에게 ${formatWon(settlement)}원 보내면 반반이에요.'
        : '내가 $partnerName 님에게 ${formatWon(settlement)}원 보내면 반반이에요.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5D9FF)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.handshake_rounded, color: AppColors.lavender),
              SizedBox(width: 8),
              Text('이번 달 반반 정산', style: TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('나 ${formatWon(mine)}원')),
              Expanded(
                child: Text(
                  '$partnerName ${formatWon(partner)}원',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            settlementText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF624AA8),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TogetherNotice extends StatelessWidget {
  const _TogetherNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class PendingPaymentsSheet extends StatefulWidget {
  const PendingPaymentsSheet({super.key, required this.payments});

  final List<PendingPayment> payments;

  @override
  State<PendingPaymentsSheet> createState() => _PendingPaymentsSheetState();
}

class _PendingPaymentsSheetState extends State<PendingPaymentsSheet> {
  final Set<int> _selectedIndexes = {};

  void _toggleAll() {
    setState(() {
      if (_selectedIndexes.length == widget.payments.length) {
        _selectedIndexes.clear();
      } else {
        _selectedIndexes
          ..clear()
          ..addAll(List.generate(widget.payments.length, (index) => index));
      }
    });
  }

  void _removeSelected() {
    final rawMessages = _selectedIndexes
        .map((index) => widget.payments[index].rawMessage)
        .toList();
    Navigator.of(context).pop(PendingPaymentsAction.remove(rawMessages));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.82,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF7FB), Color(0xFFFFFEFF)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '자동등록 알림함',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '저장 대기 ${widget.payments.length}건 · 누르면 내용을 확인해요',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _toggleAll,
                  child: Text(
                    _selectedIndexes.length == widget.payments.length
                        ? '선택 해제'
                        : '전체 선택',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              itemCount: widget.payments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final payment = widget.payments[index];
                final draft = SmsTransactionParser.parse(
                  payment.rawMessage,
                  receivedAt: payment.receivedAt,
                );
                final selected = _selectedIndexes.contains(index);
                return Material(
                  color: selected ? const Color(0xFFFFE4EF) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(PendingPaymentsAction.review(payment)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selected,
                            onChanged: (_) {
                              setState(() {
                                selected
                                    ? _selectedIndexes.remove(index)
                                    : _selectedIndexes.add(index);
                              });
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        draft?.title ?? '인식할 수 없는 알림',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (draft != null)
                                      Text(
                                        '${formatWon(draft.amount)}원',
                                        style: const TextStyle(
                                          color: Color(0xFFCE4F83),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${payment.source} · '
                                  '${formatFullDate(draft?.date ?? payment.receivedAt)}',
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedIndexes.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB42335),
                    ),
                    onPressed: _removeSelected,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text('${_selectedIndexes.length}건 알림함에서 제외'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.initialDraft,
    this.initialTransaction,
    this.onDiscard,
    required this.expenseCategories,
    required this.incomeCategories,
  });

  final SmsTransactionDraft? initialDraft;
  final BudgetTransaction? initialTransaction;
  final VoidCallback? onDiscard;
  final List<String> expenseCategories;
  final List<String> incomeCategories;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;

  late TransactionType _type;
  late String _category;
  late DateTime _date;

  List<String> get _categories {
    return _type == TransactionType.expense
        ? widget.expenseCategories
        : widget.incomeCategories;
  }

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    final transaction = widget.initialTransaction;
    _type = transaction?.type ?? draft?.type ?? TransactionType.expense;
    _titleController = TextEditingController(
      text: transaction?.title ?? draft?.title ?? '',
    );
    final initialAmount = transaction?.amount ?? draft?.amount;
    _amountController = TextEditingController(
      text: initialAmount == null ? '' : formatWon(initialAmount),
    );
    _memoController = TextEditingController(
      text: transaction?.memo ?? draft?.rawMessage ?? '',
    );
    final suggestedCategory = transaction?.category ?? draft?.category;
    final availableCategories = _type == TransactionType.expense
        ? widget.expenseCategories
        : widget.incomeCategories;
    _category =
        suggestedCategory != null &&
            availableCategories.contains(suggestedCategory)
        ? suggestedCategory
        : availableCategories.first;
    _date = transaction?.date ?? draft?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _changeType(TransactionType type) {
    setState(() {
      _type = type;
      _category = type == TransactionType.expense
          ? widget.expenseCategories.first
          : widget.incomeCategories.first;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: '거래 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
    );
    if (selected != null && mounted) {
      setState(() {
        _date = DateTime(
          selected.year,
          selected.month,
          selected.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded),
        title: const Text('이 알림을 제외할까요?'),
        content: const Text(
          '잘못 인식된 문자·Push 알림을 대기 목록에서 삭제합니다.\n'
          '가계부 내역으로는 저장되지 않아요.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('계속 확인'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('제외하기'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      widget.onDiscard?.call();
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = int.parse(_amountController.text.replaceAll(',', ''));
    Navigator.of(context).pop(
      BudgetTransaction(
        id:
            widget.initialTransaction?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        category: _category,
        amount: amount,
        type: _type,
        date: _date,
        memo: _memoController.text.trim(),
        createdBy: widget.initialTransaction?.createdBy ?? '',
        sourceApp:
            widget.initialTransaction?.sourceApp ??
            widget.initialDraft?.sourceApp ??
            '',
        installmentMonths:
            widget.initialTransaction?.installmentMonths ??
            widget.initialDraft?.installmentMonths,
        recognitionConfidence:
            widget.initialTransaction?.recognitionConfidence ??
            widget.initialDraft?.confidence,
        sourceMessageId:
            widget.initialTransaction?.sourceMessageId ??
            widget.initialDraft?.sourceMessageId ??
            '',
        isRefund:
            widget.initialTransaction?.isRefund ??
            widget.initialDraft?.isRefund ??
            false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF5FA), Color(0xFFFFFEFF)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: appGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.initialDraft != null
                            ? Icons.auto_awesome_rounded
                            : Icons.edit_note_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialDraft != null
                                ? '자동 인식 내역 확인'
                                : widget.initialTransaction == null
                                ? '내역 추가'
                                : '내역 수정',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '오늘의 기록을 차분히 남겨볼까요?',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.initialDraft != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEAF2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFC8DC)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 20,
                          color: Color(0xFFCE4F83),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '문자·Push에서 자동으로 찾은 내역이에요. '
                            '정보가 맞는지 확인해 주세요.',
                            style: TextStyle(
                              color: Color(0xFF8F3D63),
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      Chip(
                        avatar: Icon(
                          widget.initialDraft!.confidence >= 0.8
                              ? Icons.verified_rounded
                              : Icons.manage_search_rounded,
                          size: 17,
                        ),
                        label: Text(
                          widget.initialDraft!.confidence >= 0.8
                              ? '인식 정확도 높음'
                              : '한 번 더 확인 필요',
                        ),
                      ),
                      if (widget.initialDraft!.sourceApp.isNotEmpty)
                        Chip(
                          avatar: const Icon(
                            Icons.credit_card_rounded,
                            size: 17,
                          ),
                          label: Text(widget.initialDraft!.sourceApp),
                        ),
                      if (widget.initialDraft!.installmentMonths != null)
                        Chip(
                          avatar: const Icon(
                            Icons.calendar_view_month_rounded,
                            size: 17,
                          ),
                          label: Text(
                            '${widget.initialDraft!.installmentMonths}개월 할부',
                          ),
                        ),
                      if (widget.initialDraft!.isRefund)
                        const Chip(
                          avatar: Icon(
                            Icons.currency_exchange_rounded,
                            size: 17,
                          ),
                          label: Text('취소·환불'),
                        ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _confirmDiscard,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('이 알림 제외'),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2ECFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 19,
                          color: Color(0xFF7D62C8),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '사용처와 분류를 고쳐 저장하면 '
                            '다음 자동등록에 기억할게요.',
                            style: TextStyle(
                              color: Color(0xFF624AA8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('지출'),
                      icon: Icon(Icons.north_east_rounded),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('수입'),
                      icon: Icon(Icons.south_west_rounded),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) {
                    _changeType(selection.first);
                  },
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity(
                      horizontal: VisualDensity.maximumDensity,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _InputLabel('분류'),
                const SizedBox(height: 7),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: 15),
                const _InputLabel('날짜'),
                const SizedBox(height: 7),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                      suffixIcon: Icon(Icons.chevron_right_rounded),
                    ),
                    child: Text(
                      formatFullDate(_date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const _InputLabel('사용처'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '예: 이마트, 월급',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '사용처를 입력해 주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                const _InputLabel('금액'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [WonAmountInputFormatter()],
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '원',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final amount = int.tryParse(
                      (value ?? '').replaceAll(',', ''),
                    );
                    if (amount == null || amount <= 0) {
                      return '금액을 입력해 주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                const _InputLabel('메모 (선택)'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _memoController,
                  keyboardType: TextInputType.multiline,
                  minLines: widget.initialDraft == null ? 2 : 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    hintText: '기억할 내용을 적어주세요.',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: appGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x30E85D93),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      onPressed: _save,
                      child: Text(
                        widget.initialTransaction == null ? '저장하기' : '수정 완료',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700));
  }
}

bool isSameMonth(DateTime first, DateTime second) {
  return first.year == second.year && first.month == second.month;
}

DateTime previousMonth(DateTime month) {
  return DateTime(month.year, month.month - 1);
}

DateTime nextMonth(DateTime month) {
  return DateTime(month.year, month.month + 1);
}

String transactionsToCsv(List<BudgetTransaction> transactions) {
  final sorted = [...transactions]
    ..sort((first, second) => second.date.compareTo(first.date));
  final rows = <List<String>>[
    ['날짜', '구분', '분류', '사용처', '금액', '메모', '결제수단', '할부개월', '환불여부'],
    ...sorted.map(
      (item) => [
        '${item.date.year.toString().padLeft(4, '0')}-'
            '${item.date.month.toString().padLeft(2, '0')}-'
            '${item.date.day.toString().padLeft(2, '0')}',
        item.type == TransactionType.income ? '수입' : '지출',
        item.category,
        item.title,
        item.amount.toString(),
        item.memo,
        item.sourceApp,
        item.installmentMonths?.toString() ?? '',
        item.isRefund ? '환불' : '',
      ],
    ),
  ];
  return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
}

List<BudgetTransaction> transactionsFromCsv(String content) {
  final rows = _parseCsvRows(content.replaceFirst('\uFEFF', ''));
  if (rows.isEmpty) return const [];

  final headers = rows.first
      .map((value) => value.trim().replaceFirst('\uFEFF', ''))
      .toList();
  const requiredHeaders = ['날짜', '구분', '분류', '사용처', '금액', '메모'];
  for (final header in requiredHeaders) {
    if (!headers.contains(header)) {
      throw FormatException('CSV에 "$header" 열이 없습니다. 앱에서 내보낸 파일인지 확인해 주세요.');
    }
  }

  final indexes = {
    for (final header in requiredHeaders) header: headers.indexOf(header),
  };
  final transactions = <BudgetTransaction>[];
  for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
    final row = rows[rowIndex];
    if (row.every((value) => value.trim().isEmpty)) continue;

    String cell(String header) {
      final index = indexes[header]!;
      return index < row.length ? row[index].trim() : '';
    }

    String optionalCell(String header) {
      final index = headers.indexOf(header);
      return index >= 0 && index < row.length ? row[index].trim() : '';
    }

    final date = DateTime.tryParse(cell('날짜'));
    final title = _restoreCsvFormulaValue(cell('사용처'));
    final amount = int.tryParse(cell('금액').replaceAll(RegExp(r'[^0-9-]'), ''));
    if (date == null || title.isEmpty || amount == null || amount <= 0) {
      throw FormatException('${rowIndex + 1}번째 줄의 날짜, 사용처 또는 금액을 확인해 주세요.');
    }

    final typeValue = cell('구분').toLowerCase();
    final type = typeValue == '수입' || typeValue == 'income'
        ? TransactionType.income
        : TransactionType.expense;
    transactions.add(
      BudgetTransaction(
        id: 'csv_${DateTime.now().microsecondsSinceEpoch}_$rowIndex',
        title: title,
        category: _restoreCsvFormulaValue(cell('분류')).isEmpty
            ? (type == TransactionType.income ? '기타 수입' : '기타')
            : _restoreCsvFormulaValue(cell('분류')),
        amount: amount,
        type: type,
        date: DateTime(date.year, date.month, date.day),
        memo: _restoreCsvFormulaValue(cell('메모')),
        sourceApp: _restoreCsvFormulaValue(optionalCell('결제수단')),
        installmentMonths: int.tryParse(optionalCell('할부개월')),
        isRefund: optionalCell('환불여부') == '환불',
        sourceMessageId: stableMessageId(
          '${date.toIso8601String()}|$typeValue|$title|$amount|${cell('메모')}',
        ),
      ),
    );
  }
  return transactions;
}

List<List<String>> _parseCsvRows(String content) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;

  for (var index = 0; index < content.length; index++) {
    final character = content[index];
    if (character == '"') {
      if (quoted && index + 1 < content.length && content[index + 1] == '"') {
        cell.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (character == ',' && !quoted) {
      row.add(cell.toString());
      cell.clear();
    } else if ((character == '\n' || character == '\r') && !quoted) {
      row.add(cell.toString());
      cell.clear();
      if (row.any((value) => value.isNotEmpty)) rows.add(row);
      row = <String>[];
      if (character == '\r' &&
          index + 1 < content.length &&
          content[index + 1] == '\n') {
        index++;
      }
    } else {
      cell.write(character);
    }
  }
  if (quoted) {
    throw const FormatException('CSV의 따옴표 형식이 올바르지 않습니다.');
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    if (row.any((value) => value.isNotEmpty)) rows.add(row);
  }
  return rows;
}

String _restoreCsvFormulaValue(String value) {
  if (value.length >= 2 &&
      value.startsWith("'") &&
      RegExp(r'^[=+\-@\t\r]').hasMatch(value.substring(1))) {
    return value.substring(1);
  }
  return value;
}

String _csvCell(String value) {
  var safeValue = value;
  if (RegExp(r'^[=+\-@\t\r]').hasMatch(safeValue)) {
    safeValue = "'$safeValue";
  }
  return '"${safeValue.replaceAll('"', '""')}"';
}

int totalForType(List<BudgetTransaction> transactions, TransactionType type) {
  return transactions
      .where((item) => item.type == type)
      .fold<int>(
        0,
        (total, item) =>
            total +
            (type == TransactionType.expense && item.isRefund
                ? -item.amount
                : item.amount),
      );
}

String stableMessageId(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

void disposeControllerAfterDialog(TextEditingController controller) {
  unawaited(
    Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose),
  );
}

String percentageChange(int current, int previous) {
  if (previous == 0) {
    return current == 0 ? '전월과 동일' : '전월 내역 없음';
  }
  final percentage = ((current - previous) / previous * 100).abs();
  if (percentage < 0.05) {
    return '전월과 동일';
  }
  return '전월 대비 ${percentage.toStringAsFixed(1)}% '
      '${current > previous ? '증가' : '감소'}';
}

String formatMonth(DateTime date) {
  return '${date.year}년 ${date.month}월';
}

String formatDayHeader(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
}

String formatWon(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }

  return '$sign$buffer';
}

String formatDate(DateTime date) {
  return '${date.month}월 ${date.day}일';
}

String formatFullDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 '
      '(${weekdays[date.weekday - 1]})';
}

IconData categoryIcon(String category, [Map<String, String>? iconKeys]) {
  final key =
      iconKeys?[category] ??
      _runtimeCategoryIconKeys[category] ??
      defaultCategoryIconKeys[category] ??
      'more';
  return categoryIconChoices[key] ?? Icons.more_horiz_rounded;
}

class WonAmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    final limitedDigits = digits.length > 15 ? digits.substring(0, 15) : digits;
    final normalized = limitedDigits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = formatWon(int.parse(normalized));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
