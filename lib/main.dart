import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SharedBudgetApp());
}

class SharedBudgetApp extends StatelessWidget {
  const SharedBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F46E5);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '우리 가계부',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seed, width: 1.5),
          ),
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

const defaultExpenseCategories = ['식비', '카페', '교통', '쇼핑', '생활', '의료', '기타'];

const defaultIncomeCategories = ['급여', '용돈', '부수입', '기타'];

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

  Map<String, Object?> toFirestore(String userId) {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'memo': memo,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class SmsTransactionDraft {
  const SmsTransactionDraft({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.rawMessage,
  });

  final String title;
  final int amount;
  final String category;
  final DateTime date;
  final String rawMessage;
}

class SmsTransactionParser {
  static SmsTransactionDraft? parse(String rawValue) {
    final newlineIndex = rawValue.indexOf('\n');
    final message = newlineIndex >= 0
        ? rawValue.substring(newlineIndex + 1).trim()
        : rawValue.trim();

    final amountMatch = RegExp(r'([\d,]+)\s*원').firstMatch(message);
    if (amountMatch == null) {
      return null;
    }

    final amount = int.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return null;
    }

    final now = DateTime.now();
    var date = now;
    final dateMatch = RegExp(
      r'(\d{1,2})[/-](\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(message);
    if (dateMatch != null) {
      final month = int.parse(dateMatch.group(1)!);
      final day = int.parse(dateMatch.group(2)!);
      final hour = int.tryParse(dateMatch.group(3) ?? '') ?? 0;
      final minute = int.tryParse(dateMatch.group(4) ?? '') ?? 0;
      final year = month > now.month + 1 ? now.year - 1 : now.year;
      date = DateTime(year, month, day, hour, minute);
    }

    var title = '카드 결제';
    final merchantMatch = RegExp(
      r'\d{1,2}[/-]\d{1,2}(?:\s+\d{1,2}:\d{2})?\s+(.+?)\s+[\d,]+\s*원',
    ).firstMatch(message);
    if (merchantMatch != null) {
      title = merchantMatch.group(1)!.trim();
    }

    return SmsTransactionDraft(
      title: title,
      amount: amount,
      category: _categoryFor(title),
      date: date,
      rawMessage: message,
    );
  }

  static String _categoryFor(String title) {
    final value = title.toLowerCase();
    if (value.contains('스타벅스') ||
        value.contains('카페') ||
        value.contains('커피')) {
      return '카페';
    }
    if (value.contains('버스') || value.contains('택시') || value.contains('지하철')) {
      return '교통';
    }
    if (value.contains('병원') || value.contains('약국')) {
      return '의료';
    }
    if (value.contains('마트') || value.contains('식당') || value.contains('배달')) {
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

  static Future<String?> getPendingSms() {
    return _channel.invokeMethod<String>('getPendingSms');
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

class _BudgetShellState extends State<BudgetShell> {
  int _currentIndex = 0;
  bool _checkingSms = false;
  bool _loadingTransactions = true;
  String? _lastPresentedSms;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _transactionSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _categorySubscription;

  final List<BudgetTransaction> _transactions = [];
  List<String> _expenseCategories = [...defaultExpenseCategories];
  List<String> _incomeCategories = [...defaultIncomeCategories];

  String get _ledgerId => 'personal_${widget.user.uid}';

  @override
  void initState() {
    super.initState();
    _connectFirestore();
    SmsPlatformService.setNotificationTapHandler(() async {
      _lastPresentedSms = null;
      await _checkPendingSms();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await SmsPlatformService.requestPermission();
        await _checkPendingSms();
      } on MissingPluginException {
        // iOS와 위젯 테스트에서는 Android 문자 채널을 사용하지 않습니다.
      }
    });
  }

  Future<void> _connectFirestore() async {
    final database = FirebaseFirestore.instance;
    final user = widget.user;
    final userReference = database.collection('users').doc(user.uid);
    final ledgerReference = database.collection('ledgers').doc(_ledgerId);

    try {
      await userReference.set({
        'email': user.email,
        'inviteCode': user.uid.substring(0, 8).toUpperCase(),
        'appBuild': '2026.07.31.1',
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await ledgerReference.set({
        'name': '내 가계부',
        'memberIds': [user.uid],
        'createdBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final ledgerSnapshot = await ledgerReference.get();
      final ledgerData = ledgerSnapshot.data() ?? {};
      if (ledgerData['expenseCategories'] == null ||
          ledgerData['incomeCategories'] == null) {
        await ledgerReference.update({
          'expenseCategories': defaultExpenseCategories,
          'incomeCategories': defaultIncomeCategories,
        });
      }
      _categorySubscription = ledgerReference.snapshots().listen((snapshot) {
        final data = snapshot.data();
        if (data == null || !mounted) {
          return;
        }
        final expenses = (data['expenseCategories'] as List<dynamic>?)
            ?.whereType<String>()
            .toList();
        final incomes = (data['incomeCategories'] as List<dynamic>?)
            ?.whereType<String>()
            .toList();
        setState(() {
          _expenseCategories = expenses == null || expenses.isEmpty
              ? [...defaultExpenseCategories]
              : expenses;
          _incomeCategories = incomes == null || incomes.isEmpty
              ? [...defaultIncomeCategories]
              : incomes;
        });
      });

      _transactionSubscription = ledgerReference
          .collection('transactions')
          .orderBy('date', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final transactions = snapshot.docs.map((document) {
                final data = document.data();
                final timestamp = data['date'];
                return BudgetTransaction(
                  id: document.id,
                  title: data['title'] as String? ?? '이름 없음',
                  category: data['category'] as String? ?? '기타',
                  amount: (data['amount'] as num?)?.toInt() ?? 0,
                  type: data['type'] == TransactionType.income.name
                      ? TransactionType.income
                      : TransactionType.expense,
                  date: timestamp is Timestamp
                      ? timestamp.toDate()
                      : DateTime.now(),
                  memo: data['memo'] as String? ?? '',
                );
              }).toList();

              if (mounted) {
                setState(() {
                  _transactions
                    ..clear()
                    ..addAll(transactions);
                  _loadingTransactions = false;
                });
              }
            },
            onError: (_) {
              if (mounted) {
                setState(() => _loadingTransactions = false);
                _showMessage('거래 내역을 불러오지 못했습니다.');
              }
            },
          );
    } on FirebaseException catch (error) {
      debugPrint('Firestore connection failed: ${error.code} ${error.message}');
      if (mounted) {
        setState(() => _loadingTransactions = false);
        _showMessage(_firestoreErrorMessage(error));
      }
    }
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    _categorySubscription?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _checkPendingSms() async {
    if (_checkingSms || !mounted) {
      return;
    }

    _checkingSms = true;
    try {
      final rawSms = await SmsPlatformService.getPendingSms();
      if (rawSms == null || rawSms.trim().isEmpty) {
        return;
      }
      if (_lastPresentedSms == rawSms) {
        return;
      }

      _lastPresentedSms = rawSms;
      final draft = SmsTransactionParser.parse(rawSms);
      if (!mounted) {
        return;
      }

      if (draft == null) {
        await SmsPlatformService.clearPendingSms();
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

      final saved = await _openAddTransaction(draft: draft);
      if (saved) {
        await SmsPlatformService.clearPendingSms();
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
    await FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId)
        .collection('transactions')
        .add(transaction.toFirestore(widget.user.uid));
  }

  Future<bool> _openAddTransaction({SmsTransactionDraft? draft}) async {
    final result = await showModalBottomSheet<BudgetTransaction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        initialDraft: draft,
        expenseCategories: _expenseCategories,
        incomeCategories: _incomeCategories,
      ),
    );

    if (result != null) {
      try {
        await _addTransaction(result);
        if (mounted) {
          _showMessage('거래가 저장되었습니다.');
        }
        return true;
      } on FirebaseException catch (error) {
        debugPrint(
          'Firestore transaction save failed: ${error.code} ${error.message}',
        );
        if (mounted) {
          _showMessage(_firestoreErrorMessage(error));
        }
        return false;
      }
    }
    return false;
  }

  Future<void> _saveCategories({
    required List<String> expenses,
    required List<String> incomes,
  }) async {
    await FirebaseFirestore.instance
        .collection('ledgers')
        .doc(_ledgerId)
        .update({
          'expenseCategories': expenses,
          'incomeCategories': incomes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _openCategoryManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CategoryManagerPage(
          expenseCategories: _expenseCategories,
          incomeCategories: _incomeCategories,
          onSave: _saveCategories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(transactions: _transactions, isLoading: _loadingTransactions),
      TransactionsPage(
        transactions: _transactions,
        isLoading: _loadingTransactions,
      ),
      StatisticsPage(
        transactions: _transactions,
        isLoading: _loadingTransactions,
      ),
      TogetherPage(user: widget.user, onManageCategories: _openCategoryManager),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton.extended(
              onPressed: () => _openAddTransaction(),
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
  });

  final List<BudgetTransaction> transactions;
  final bool isLoading;

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

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverList.list(
              children: [
                const _HomeHeader(),
                const SizedBox(height: 22),
                _SummaryCard(
                  income: income,
                  expense: expense,
                  month: now.month,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '최근 내역',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${transactions.length}건',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
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
                      return TransactionTile(transaction: transactions[index]);
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
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
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
                '함께 모으고, 함께 확인해요',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: '알림',
        ),
      ],
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
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x294F46E5),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$month월 남은 금액',
            style: const TextStyle(color: Color(0xFFDAD7FE), fontSize: 14),
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
              Text(label, style: const TextStyle(color: Color(0xFFDAD7FE))),
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
  });

  final List<BudgetTransaction> transactions;
  final bool isLoading;

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
          ..sort((a, b) => b.date.compareTo(a.date));
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
        color: Colors.white,
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
        color: Colors.white,
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
        color: Colors.white,
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
  });

  final BudgetTransaction transaction;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = categoryIcon(transaction.category);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
            Text(
              '${isExpense ? '-' : '+'}${formatWon(transaction.amount)}원',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 46, color: Color(0xFFD1D5DB)),
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
    required this.onSave,
  });

  final List<String> expenseCategories;
  final List<String> incomeCategories;
  final Future<void> Function({
    required List<String> expenses,
    required List<String> incomes,
  })
  onSave;

  @override
  State<CategoryManagerPage> createState() => _CategoryManagerPageState();
}

class _CategoryManagerPageState extends State<CategoryManagerPage> {
  final _controller = TextEditingController();
  late List<String> _expenses;
  late List<String> _incomes;
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
      _controller.clear();
    });
  }

  void _removeCategory(String category) {
    if (_selectedCategories.length == 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('분류를 한 개 이상 남겨주세요.')));
      return;
    }
    setState(() => _selectedCategories.remove(category));
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(expenses: _expenses, incomes: _incomes);
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
                        leading: Icon(categoryIcon(category)),
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

class TogetherPage extends StatelessWidget {
  const TogetherPage({
    super.key,
    required this.user,
    required this.onManageCategories,
  });

  final User user;
  final VoidCallback onManageCategories;

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

  @override
  Widget build(BuildContext context) {
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
                            Icons.group_add_rounded,
                            size: 34,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '아직 함께하는 사람이 없어요',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '다음 단계에서 초대 코드와\n승인 기능을 연결할 예정입니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
                                '내 초대 코드: '
                                '${user.uid.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Firebase 연결 후 사용할 수 있어요.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('초대하기'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: onManageCategories,
                          icon: const Icon(Icons.category_outlined),
                          label: const Text('분류 관리'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email ?? '사용자',
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

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.initialDraft,
    required this.expenseCategories,
    required this.incomeCategories,
  });

  final SmsTransactionDraft? initialDraft;
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

  TransactionType _type = TransactionType.expense;
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
    _titleController = TextEditingController(text: draft?.title ?? '');
    _amountController = TextEditingController(
      text: draft == null ? '' : draft.amount.toString(),
    );
    _memoController = TextEditingController(
      text: draft == null ? '' : '문자 자동입력',
    );
    final suggestedCategory = draft?.category;
    _category =
        suggestedCategory != null &&
            widget.expenseCategories.contains(suggestedCategory)
        ? suggestedCategory
        : widget.expenseCategories.first;
    _date = draft?.date ?? DateTime.now();
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

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = int.parse(_amountController.text.replaceAll(',', ''));
    Navigator.of(context).pop(
      BudgetTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
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
        color: Colors.white,
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
                const Text(
                  '내역 추가',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '원',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final amount = int.tryParse(value ?? '');
                    if (amount == null || amount <= 0) {
                      return '금액을 입력해 주세요.';
                    }
                    return null;
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
                const _InputLabel('메모 (선택)'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _memoController,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    hintText: '기억할 내용을 적어주세요.',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text(
                      '저장하기',
                      style: TextStyle(
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

IconData categoryIcon(String category) {
  return switch (category) {
    '식비' => Icons.restaurant_rounded,
    '카페' => Icons.local_cafe_rounded,
    '교통' => Icons.directions_bus_rounded,
    '쇼핑' => Icons.shopping_bag_rounded,
    '생활' => Icons.home_rounded,
    '의료' => Icons.local_hospital_rounded,
    '급여' => Icons.account_balance_rounded,
    '용돈' => Icons.savings_rounded,
    '부수입' => Icons.trending_up_rounded,
    _ => Icons.more_horiz_rounded,
  };
}
