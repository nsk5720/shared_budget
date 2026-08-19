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

  test('무료 학습 규칙은 공백과 대소문자 차이를 무시한다', () {
    expect(
      merchantRuleKey('스타 벅스', TransactionType.expense),
      merchantRuleKey('스타벅스', TransactionType.expense),
    );
    expect(
      merchantRuleKey('GS25', TransactionType.expense),
      merchantRuleKey('gs25', TransactionType.expense),
    );
  });

  test('상태 문구는 사용처 학습 대상에서 제외한다', () {
    expect(isLearnableMerchantTitle('스타벅스'), isTrue);
    expect(isLearnableMerchantTitle('카드 결제'), isFalse);
    expect(isLearnableMerchantTitle('완료'), isFalse);
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
    expect(draft.rawMessage, '15881234\n[우리카드] 07/30 14:20 스타벅스 5,800원 승인');
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
    expect(draft.rawMessage, '우리카드\n[우리카드] 스타벅스 ₩5,800 승인\n08/11 14:20');
  });

  test('입금 Push 알림은 수입으로 구분한다', () {
    final draft = SmsTransactionParser.parse(
      '토스\n김민수님에게 30,000원 입금 08/11 15:00',
    );

    expect(draft, isNotNull);
    expect(draft!.amount, 30000);
    expect(draft.type, TransactionType.income);
    expect(draft.title, '김민수');
  });

  test('잔액이 함께 있어도 실제 결제 금액을 선택한다', () {
    final draft = SmsTransactionParser.parse(
      '신한카드\n08/12 18:31 배달의민족 24,900원 승인\n잔액 1,245,100원',
    );

    expect(draft, isNotNull);
    expect(draft!.title, '배달의민족');
    expect(draft.amount, 24900);
    expect(draft.category, '식비');
  });

  test('금액이 먼저 나오는 Push에서 사용처와 쇼핑 분류를 찾는다', () {
    final draft = SmsTransactionParser.parse(
      '카카오페이\n35,000원 결제 올리브영 08/12 13:05',
    );

    expect(draft, isNotNull);
    expect(draft!.title, '올리브영');
    expect(draft.amount, 35000);
    expect(draft.category, '쇼핑');
  });

  test('한글 날짜와 급여 입금을 인식한다', () {
    final draft = SmsTransactionParser.parse(
      '토스\n8월 12일 09:01 주식회사마음에서 급여 3,200,000원 입금',
    );

    expect(draft, isNotNull);
    expect(draft!.amount, 3200000);
    expect(draft.type, TransactionType.income);
    expect(draft.category, '급여');
    expect(draft.title, '주식회사마음');
    expect(draft.date.month, 8);
    expect(draft.date.day, 12);
  });

  test('두 자리 연도와 요일이 포함된 날짜를 인식한다', () {
    final draft = SmsTransactionParser.parse(
      '신한카드\n26.08.17(월) 19:42 스타벅스 5,800원 승인',
    );

    expect(draft, isNotNull);
    expect(draft!.date, DateTime(2026, 8, 17, 19, 42));
  });

  test('한글 날짜와 오후 시간을 인식한다', () {
    final draft = SmsTransactionParser.parse(
      '우리카드\n2026년 8월 16일 오후 3시 25분 이마트 42,000원 승인',
    );

    expect(draft, isNotNull);
    expect(draft!.date, DateTime(2026, 8, 16, 15, 25));
  });

  test('본문에 날짜가 없으면 실제 알림 수신 시각을 사용한다', () {
    final receivedAt = DateTime(2026, 8, 15, 22, 31);
    final draft = SmsTransactionParser.parse(
      '삼성카드\n스타벅스 5,800원 승인',
      receivedAt: receivedAt,
    );

    expect(draft, isNotNull);
    expect(draft!.date, receivedAt);
  });

  test('KRW 표시 금액도 인식한다', () {
    final draft = SmsTransactionParser.parse(
      '현대카드\nKRW 18,500 승인 교보문고 08/12 16:20',
    );

    expect(draft, isNotNull);
    expect(draft!.amount, 18500);
    expect(draft.title, '교보문고');
  });

  test('출금 완료에서 완료를 사용처로 넣지 않는다', () {
    final draft = SmsTransactionParser.parse(
      '토스\n15,000원 출금 완료\n스타벅스\n08/12 16:30',
    );

    expect(draft, isNotNull);
    expect(draft!.title, '스타벅스');
    expect(draft.title, isNot('완료'));
  });

  test('결제 완료와 사용처가 같은 줄이어도 사용처만 남긴다', () {
    final draft = SmsTransactionParser.parse(
      '카카오페이\n22,000원 결제완료 배달의민족 08/12 19:20',
    );

    expect(draft, isNotNull);
    expect(draft!.title, '배달의민족');
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
    expect(find.text('자동 인식 내역 확인'), findsOneWidget);
    expect(find.text('이 알림 제외'), findsOneWidget);
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

  test('가계부 내역을 안전한 CSV로 만든다', () {
    final csv = transactionsToCsv([
      BudgetTransaction(
        id: 'one',
        title: '=위험한 수식',
        category: '쇼핑',
        amount: 12000,
        type: TransactionType.expense,
        date: DateTime(2026, 8, 19),
        memo: '쿠폰 "사용"',
      ),
    ]);

    expect(csv, contains('"날짜","구분","분류","사용처","금액","메모"'));
    expect(csv, contains('"\'=위험한 수식"'));
    expect(csv, contains('"쿠폰 ""사용"""'));
  });

  test('CSV 파일을 다시 가져오면 원래 내역이 복원된다', () {
    final original = BudgetTransaction(
      id: 'one',
      title: '동네, 카페',
      category: '카페',
      amount: 5800,
      type: TransactionType.expense,
      date: DateTime(2026, 8, 19),
      memo: '쿠폰 "사용"\n친구와 방문',
    );

    final restored = transactionsFromCsv(transactionsToCsv([original]));

    expect(restored, hasLength(1));
    expect(restored.single.title, original.title);
    expect(restored.single.category, original.category);
    expect(restored.single.amount, original.amount);
    expect(restored.single.type, original.type);
    expect(restored.single.date, original.date);
    expect(restored.single.memo, original.memo);
  });

  test('필수 열이 없는 CSV는 친절한 오류를 낸다', () {
    expect(
      () => transactionsFromCsv('날짜,금액\n2026-08-19,1000'),
      throwsA(isA<FormatException>()),
    );
  });

  test('반복 내역 설정을 Firestore 데이터에서 복원한다', () {
    final rule = RecurringTransactionRule.fromMap({
      'id': 'rent',
      'title': '월세',
      'category': '생활',
      'amount': 500000,
      'type': 'expense',
      'day': 31,
      'memo': '관리비 제외',
      'enabled': true,
    });

    expect(rule, isNotNull);
    expect(rule!.title, '월세');
    expect(rule.day, 31);
    expect(rule.amount, 500000);
  });
}
