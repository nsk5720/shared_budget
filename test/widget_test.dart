import 'package:flutter_test/flutter_test.dart';
import 'package:shared_budget/main.dart';

void main() {
  testWidgets('가계부 홈과 거래 추가 화면이 표시된다', (tester) async {
    await tester.pumpWidget(const SharedBudgetApp());

    expect(find.text('우리 가계부'), findsOneWidget);
    expect(find.text('7월 남은 금액'), findsOneWidget);
    expect(find.text('내역 추가'), findsOneWidget);

    await tester.tap(find.text('내역 추가'));
    await tester.pumpAndSettle();

    expect(find.text('저장하기'), findsOneWidget);
    expect(find.text('사용처'), findsOneWidget);
    expect(find.text('금액'), findsOneWidget);
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
  });
}
