import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_budget/main.dart';

void main() {
  testWidgets('로그인과 회원가입 화면을 전환한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);

    await tester.tap(find.text('처음이신가요? 회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('우리 가계부 시작하기'), findsOneWidget);
  });

  test('금액에 천 단위 쉼표를 넣는다', () {
    expect(formatWon(3200000), '3,200,000');
    expect(formatWon(-12500), '-12,500');
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
}
