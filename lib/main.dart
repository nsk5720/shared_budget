import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class SharedBudgetApp extends StatelessWidget {
  const SharedBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFE86A9D);
    const background = Color(0xFFFFF8FB);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '우리 가계부',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFFFFBFD),
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFFFFFEFF),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFFFE5EF)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFEFF5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: seed, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE86A9D),
          foregroundColor: Colors.white,
          shape: StadiumBorder(),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFFBFD),
          indicatorColor: const Color(0xFFFFD9E8),
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFB83F73)
                  : const Color(0xFF7E6E76),
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            );
          }),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const AuthGate(),
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
          '우리 가계부의 아이디는 회원가입할 때 사용한 이메일 주소입니다.\n\n'
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
    resetEmailController.dispose();

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재설정 메일을 보냈습니다. 메일함과 스팸함을 확인해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _isSignUp ? '우리 가계부 시작하기' : '다시 만나서 반가워요',
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
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
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
                            onPressed: _isLoading ? null : _showPasswordReset,
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

const defaultExpenseCategories = ['식비', '카페', '교통', '쇼핑', '생활', '의료', '기타'];

const defaultIncomeCategories = ['급여', '용돈', '부수입', '기타'];

const defaultCategoryIconKeys = <String, String>{
  '식비': 'restaurant',
  '카페': 'cafe',
  '교통': 'bus',
  '쇼핑': 'shopping',
  '생활': 'home',
  '의료': 'medical',
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
  });

  final String id;
  final String title;
  final String category;
  final int amount;
  final TransactionType type;
  final DateTime date;
  final String memo;

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
      'updatedAt': FieldValue.serverTimestamp(),
    };
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

class SmsTransactionDraft {
  const SmsTransactionDraft({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.rawMessage,
    this.type = TransactionType.expense,
  });

  final String title;
  final int amount;
  final String category;
  final DateTime date;
  final String rawMessage;
  final TransactionType type;
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

  static SmsTransactionDraft? parse(String rawValue) {
    final rawMessage = rawValue.trim();
    if (rawMessage.isEmpty) {
      return null;
    }
    final message = _contentWithoutSource(rawMessage);
    final parsedAmount = _findTransactionAmount(message);
    if (parsedAmount == null) {
      return null;
    }

    final type = _incomeKeywords.hasMatch(message)
        ? TransactionType.income
        : TransactionType.expense;
    final title = _findTitle(message, parsedAmount.match, type);
    return SmsTransactionDraft(
      title: title,
      amount: parsedAmount.value,
      category: _categoryFor(title, message, type),
      date: _findDate(message),
      rawMessage: rawMessage,
      type: type,
    );
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

  static DateTime _findDate(String message) {
    final now = DateTime.now();
    final fullDate = RegExp(
      r'(20\d{2})[./-](\d{1,2})[./-](\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(message);
    if (fullDate != null) {
      return _safeDate(
        int.parse(fullDate.group(1)!),
        int.parse(fullDate.group(2)!),
        int.parse(fullDate.group(3)!),
        int.tryParse(fullDate.group(4) ?? '') ?? 0,
        int.tryParse(fullDate.group(5) ?? '') ?? 0,
        now,
      );
    }
    final shortDate = RegExp(
      r'(\d{1,2})[./-](\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(message);
    final koreanDate = RegExp(
      r'(\d{1,2})월\s*(\d{1,2})일(?:\s+(\d{1,2}):?(\d{2}))?',
    ).firstMatch(message);
    final match = shortDate ?? koreanDate;
    if (match == null) {
      return now;
    }
    final month = int.parse(match.group(1)!);
    final year = month > now.month + 1 ? now.year - 1 : now.year;
    return _safeDate(
      year,
      month,
      int.parse(match.group(2)!),
      int.tryParse(match.group(3) ?? '') ?? 0,
      int.tryParse(match.group(4) ?? '') ?? 0,
      now,
    );
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

  static Future<String?> getPendingSms() {
    return _channel.invokeMethod<String>('getPendingSms');
  }

  static Future<int> getPendingPaymentCount() async {
    return await _channel.invokeMethod<int>('getPendingPaymentCount') ?? 0;
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
  String? _lastPresentedSms;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _transactionSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ledgerSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _categorySubscription;

  final List<BudgetTransaction> _transactions = [];
  List<String> _expenseCategories = [...defaultExpenseCategories];
  List<String> _incomeCategories = [...defaultIncomeCategories];
  Map<String, String> _categoryIconKeys = {...defaultCategoryIconKeys};
  Map<String, String> _merchantCategoryRules = {};
  Map<String, String> _merchantTitleRules = {};
  String _ledgerId = '';
  String _ledgerName = '내 가계부';
  List<String> _ledgerMemberEmails = [];
  List<LedgerOption> _availableLedgers = [];
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> _ledgerDocuments =
      {};
  String? _preferredLedgerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
              '우리 가계부는 새로 수신되는 결제 SMS 문자와 은행·카드 앱이 '
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
            '다음 화면에서 ‘우리 가계부 결제 알림 읽기’를 찾아 켜 주세요. '
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
        'appBuild': '2026.08.11.2',
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
    if (source.docs.isEmpty) {
      return 0;
    }

    final target = database
        .collection('ledgers')
        .doc(_ledgerId)
        .collection('transactions');
    const batchSize = 400;
    for (var start = 0; start < source.docs.length; start += batchSize) {
      final end = (start + batchSize < source.docs.length)
          ? start + batchSize
          : source.docs.length;
      final batch = database.batch();
      for (final document in source.docs.sublist(start, end)) {
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
    return source.docs.length;
  }

  void _activateLedger(DocumentSnapshot<Map<String, dynamic>> ledgerDocument) {
    final data = ledgerDocument.data() ?? {};
    final memberEmails =
        (data['memberEmails'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        [];

    if (_ledgerId == ledgerDocument.id) {
      if (mounted) {
        setState(() {
          _ledgerName = data['name'] as String? ?? '우리 가계부';
          _ledgerMemberEmails = memberEmails;
        });
      }
      return;
    }

    _transactionSubscription?.cancel();
    _categorySubscription?.cancel();
    _ledgerId = ledgerDocument.id;

    if (mounted) {
      setState(() {
        _ledgerName = data['name'] as String? ?? '우리 가계부';
        _ledgerMemberEmails = memberEmails;
        _loadingTransactions = true;
        _transactions.clear();
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
      setState(() {
        _ledgerName = ledgerData['name'] as String? ?? '우리 가계부';
        _ledgerMemberEmails = emails;
        _expenseCategories = expenses == null || expenses.isEmpty
            ? [...defaultExpenseCategories]
            : expenses;
        _incomeCategories = incomes == null || incomes.isEmpty
            ? [...defaultIncomeCategories]
            : incomes;
        _categoryIconKeys = {...defaultCategoryIconKeys, ...?iconKeys};
        _merchantCategoryRules = {...?merchantRules};
        _merchantTitleRules = {...?merchantTitleRules};
        _runtimeCategoryIconKeys
          ..clear()
          ..addAll(_categoryIconKeys);
      });
    });

    _transactionSubscription = ledgerReference
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final transactions = snapshot.docs.map((document) {
              final transactionData = document.data();
              final timestamp = transactionData['date'];
              return BudgetTransaction(
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
              );
            }).toList();

            if (mounted) {
              setState(() {
                _transactions
                  ..clear()
                  ..addAll(transactions);
                _loadingTransactions = false;
                _connectionError = null;
              });
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
    await _refreshPendingPaymentCount();
    if (!mounted) {
      return;
    }
    if (_pendingPaymentCount > 0) {
      _lastPresentedSms = null;
      await _checkPendingSms();
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

  Future<void> _checkPendingSms() async {
    if (_checkingSms || !mounted) {
      return;
    }

    _checkingSms = true;
    try {
      final rawSms = await SmsPlatformService.getPendingSms();
      if (rawSms == null || rawSms.trim().isEmpty) {
        if (mounted) {
          setState(() => _pendingPaymentCount = 0);
        }
        return;
      }
      if (_lastPresentedSms == rawSms) {
        return;
      }

      _lastPresentedSms = rawSms;
      var draft = SmsTransactionParser.parse(rawSms);
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

  Future<void> _addTransaction(BudgetTransaction transaction) async {
    if (_ledgerId.isEmpty) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
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
          '삭제한 내역은 되돌릴 수 없습니다.',
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
          .delete()
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        _showMessage('내역을 삭제했습니다.');
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
    final pages = [
      HomePage(
        transactions: _transactions,
        isLoading: _loadingTransactions,
        pendingPaymentCount: _pendingPaymentCount,
        onNotificationsPressed: _openPendingPayments,
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
        availableLedgers: _availableLedgers,
        onSelectLedger: _switchLedger,
        onImportPersonalTransactions: _importPersonalTransactions,
        ledgerId: _ledgerId,
        ledgerName: _ledgerName,
        memberEmails: _ledgerMemberEmails,
      ),
    ];

    return Scaffold(
      body: Column(
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
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton.extended(
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
              label: const Text('내역 추가'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
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
    );
  }
}

String _firestoreErrorMessage(FirebaseException error) {
  return switch (error.code) {
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
    required this.pendingPaymentCount,
    required this.onNotificationsPressed,
    required this.onViewAll,
    required this.onTransactionTap,
  });

  final List<BudgetTransaction> transactions;
  final bool isLoading;
  final int pendingPaymentCount;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onViewAll;
  final ValueChanged<BudgetTransaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlyTransactions = transactions
        .where((item) => isSameMonth(item.date, now))
        .toList();
    final income = monthlyTransactions
        .where((item) => item.type == TransactionType.income)
        .fold<int>(0, (total, item) => total + item.amount);
    final expense = monthlyTransactions
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (total, item) => total + item.amount);
    final todayExpense = transactions
        .where(
          (item) =>
              item.type == TransactionType.expense &&
              item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day,
        )
        .fold<int>(0, (total, item) => total + item.amount);
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
                ),
                const SizedBox(height: 22),
                _SummaryCard(
                  income: income,
                  expense: expense,
                  month: now.month,
                ),
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
  });

  final int pendingPaymentCount;
  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            Icons.savings_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '우리 가계부',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2),
              Text(
                '알콩달콩 모으고, 함께 확인해요 ♥',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              onPressed: onNotificationsPressed,
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: '자동등록 알림함',
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
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDDEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FE86A9D),
            blurRadius: 16,
            offset: Offset(0, 7),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF17AA8), Color(0xFFA786E8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33E86A9D),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
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

  @override
  Widget build(BuildContext context) {
    final monthlyTransactions =
        widget.transactions
            .where((item) => isSameMonth(item.date, _selectedMonth))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
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
          const SizedBox(height: 8),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
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
                      final dayExpense = dayTransactions
                          .where((item) => item.type == TransactionType.expense)
                          .fold<int>(0, (total, item) => total + item.amount);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
                              child: Row(
                                children: [
                                  Text(
                                    formatDayHeader(day),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
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
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(16),
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
                              color: const Color(0xFF10B981),
                              icon: Icons.south_west_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatSummaryCard(
                              label: '지출',
                              amount: expense,
                              previousAmount: previousExpense,
                              color: const Color(0xFFEF4444),
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
                              (item) => item.type == TransactionType.expense,
                            )
                            .toList(),
                        color: const Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 14),
                      _CategoryStatistics(
                        title: '수입 분류',
                        transactions: current
                            .where(
                              (item) => item.type == TransactionType.income,
                            )
                            .toList(),
                        color: const Color(0xFF10B981),
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
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(18),
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
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
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
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(20),
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
    final color = isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = categoryIcon(transaction.category);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
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
                      showDate
                          ? '${transaction.category} · '
                                '${formatDate(transaction.date)}'
                          : transaction.category,
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
                    '${isExpense ? '-' : '+'}${formatWon(transaction.amount)}원',
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
      body: SafeArea(
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
    );
  }
}

class TogetherPage extends StatefulWidget {
  const TogetherPage({
    super.key,
    required this.user,
    required this.onManageCategories,
    required this.availableLedgers,
    required this.onSelectLedger,
    required this.onImportPersonalTransactions,
    required this.ledgerId,
    required this.ledgerName,
    required this.memberEmails,
  });

  final User user;
  final VoidCallback onManageCategories;
  final List<LedgerOption> availableLedgers;
  final ValueChanged<String> onSelectLedger;
  final Future<int> Function() onImportPersonalTransactions;
  final String ledgerId;
  final String ledgerName;
  final List<String> memberEmails;

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
    controller.dispose();

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
                IconButton.filledTonal(
                  onPressed: () => _confirmSignOut(context),
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: '로그아웃',
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isShared
                                ? Icons.people_rounded
                                : _hasSharedLedger
                                ? Icons.person_rounded
                                : Icons.group_add_rounded,
                            size: 34,
                            color: Theme.of(context).colorScheme.primary,
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
                          Text(
                            widget.ledgerName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
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
                        OutlinedButton.icon(
                          onPressed: widget.onManageCategories,
                          icon: const Icon(Icons.category_outlined),
                          label: const Text('분류 관리'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBFD),
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
                  child: FilledButton(
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

int totalForType(List<BudgetTransaction> transactions, TransactionType type) {
  return transactions
      .where((item) => item.type == type)
      .fold<int>(0, (total, item) => total + item.amount);
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
