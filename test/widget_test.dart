import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_budget/main.dart';

void main() {
  testWidgets('로그인과 회원가입 화면을 전환한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('아이디 찾기'), findsOneWidget);
    expect(find.text('비밀번호 재설정'), findsOneWidget);

    await tester.tap(find.text('아이디 찾기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아이디는 회원가입할 때 사용한 이메일'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('비밀번호 재설정'));
    await tester.pumpAndSettle();
    expect(find.text('재설정 메일 보내기'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('처음이신가요? 회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('우리 가계부 시작하기'), findsOneWidget);
  });

  test('금액에 천 단위 쉼표를 넣는다', () {
    expect(formatWon(3200000), '3,200,000');
    expect(formatWon(-12500), '-12,500');
  });

  test('금액 입력 중 천 단위 쉼표를 자동 적용한다', () {
    final result = WonAmountInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1234567'),
    );

    expect(result.text, '1,234,567');
    expect(result.selection.baseOffset, 9);
  });

  test('사용자가 선택한 분류 아이콘을 표시한다', () {
    expect(categoryIcon('반려동물', const {'반려동물': 'pet'}), Icons.pets_rounded);
  });

  test('카드 문자에서 거래 초안을 만든다', () {
    final draft = SmsTransactionParser.parse(
      '15881234\n[우리카드] 07/30 14:20 스타벅스 5,800원 승인',
    );

    expect(draft, isNotNull);
    expect(draft!.title, '스타벅스');
    expect(draft.amount, 5800);
    expect(draft.category, '카페');
    expect(draft.date.month, 7);
    expect(draft.date.day, 30);
    expect(draft.rawMessage, '[우리카드] 07/30 14:20 스타벅스 5,800원 승인');
  });

  test('카드 Push 알림에서 원화 기호 금액과 사용처를 읽는다', () {
    final draft = SmsTransactionParser.parse(
      '우리카드\n[우리카드] 스타벅스 ₩5,800 승인\n08/11 14:20',
    );

    expect(draft, isNotNull);
    expect(draft!.title, '스타벅스');
    expect(draft.amount, 5800);
    expect(draft.category, '카페');
    expect(draft.date.month, 8);
    expect(draft.date.day, 11);
    expect(draft.rawMessage, '[우리카드] 스타벅스 ₩5,800 승인\n08/11 14:20');
  });

  test('입금 Push 알림은 수입으로 구분한다', () {
    final draft = SmsTransactionParser.parse(
      '토스\n김민수님에게 30,000원 입금 08/11 15:00',
    );

    expect(draft, isNotNull);
    expect(draft!.amount, 30000);
    expect(draft.type, TransactionType.income);
  });

  testWidgets('문자 원문을 내역 메모에 자동 입력한다', (tester) async {
    const rawMessage = '[우리카드] 07/30 14:20 스타벅스 5,800원 승인';
    final draft = SmsTransactionDraft(
      title: '스타벅스',
      amount: 5800,
      category: '카페',
      date: DateTime(2026, 7, 30, 14, 20),
      rawMessage: rawMessage,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTransactionSheet(
            initialDraft: draft,
            expenseCategories: defaultExpenseCategories,
            incomeCategories: defaultIncomeCategories,
          ),
        ),
      ),
    );

    expect(find.text(rawMessage), findsOneWidget);
  });

  testWidgets('기존 내역 수정 화면에 금액을 쉼표로 표시한다', (tester) async {
    final transaction = BudgetTransaction(
      id: 'transaction-1',
      title: '대형마트',
      category: '식비',
      amount: 1234567,
      type: TransactionType.expense,
      date: DateTime(2026, 8, 11),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddTransactionSheet(
            initialTransaction: transaction,
            expenseCategories: defaultExpenseCategories,
            incomeCategories: defaultIncomeCategories,
          ),
        ),
      ),
    );

    expect(find.text('내역 수정'), findsOneWidget);
    expect(find.text('1,234,567'), findsOneWidget);
    expect(find.text('수정 완료'), findsOneWidget);
  });

  test('전월 대비 증가와 감소 비율을 계산한다', () {
    expect(percentageChange(120, 100), '전월 대비 20.0% 증가');
    expect(percentageChange(80, 100), '전월 대비 20.0% 감소');
    expect(percentageChange(0, 0), '전월과 동일');
  });

  test('1월의 이전 달은 전년도 12월이다', () {
    final result = previousMonth(DateTime(2026, 1));

    expect(result.year, 2025);
    expect(result.month, 12);
  });

  test('개인 가계부와 공동 가계부를 구분한다', () {
    const personal = LedgerOption(
      id: 'personal_user-a',
      name: '내 가계부',
      memberEmails: ['a@example.com'],
    );
    const shared = LedgerOption(
      id: 'shared_invitation-a',
      name: '공동 가계부',
      memberEmails: ['a@example.com', 'b@example.com'],
    );

    expect(personal.isShared, isFalse);
    expect(shared.isShared, isTrue);
  });
}
