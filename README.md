# 우리 가계부

초대와 승인을 통해 원하는 사람과 함께 사용하는 Flutter 가계부 앱입니다.

## 현재 구현

- 이번 달 수입·지출·잔액 요약
- 이메일 회원가입·로그인
- 로그인 상태 유지
- 사용자별 개인 가계부 생성
- Firestore 거래 실시간 저장·불러오기
- 최근 거래와 전체 거래 목록
- 수입·지출 직접 입력
- 거래 날짜 직접 선택
- 거래 분류 선택
- 월별·날짜별 거래 목록
- 월별 수입·지출 분류 통계
- 전월 대비 증감률
- 사용자 분류 추가·삭제 및 Firebase 저장
- Android 결제 문자 수신
- 앱이 닫혀 있어도 결제 확인 알림 표시
- 알림을 눌러 거래 확인 화면 열기
- 여러 결제 문자를 순서대로 대기
- 미저장 문자 개수를 알림에 표시
- 날짜·사용처·금액 자동 분석
- 저장하기 전까지 알림과 거래 초안 유지
- 분석 결과 확인 후 저장
- 함께쓰기 안내 화면

## 실행

```powershell
flutter run
```

다음 개발 단계는 초대·승인과 공동 가계부 동기화입니다.

## 가상 문자 테스트

Android Emulator의 `Extended controls > Phone`에서 아래 형식의 SMS를
전송합니다.

```text
[우리카드] 07/30 14:20 스타벅스 5,800원 승인
```

문자가 도착하면 앱에 거래 확인 화면이 자동으로 표시됩니다.

## AI 자동분석 설정

문자·Push는 기본 규칙으로 먼저 분석하고, `함께쓰기 > AI 자동분석`을
켠 경우에만 Firebase Cloud Function이 OpenAI API로 사용처와 분류를
한 번 더 확인합니다. 카드번호·전화번호 등은 전송 전에 가리고,
원문 전체는 AI 결과로 덮어쓰지 않으며 내역의 메모에 보존합니다.

### 최초 1회 배포

Firebase Cloud Functions와 OpenAI API는 과금 계정이 필요합니다.

```cmd
cd /d C:\Users\Solomonm\Documents\Codex\2026-07-30\id-db\shared_budget\functions
"C:\Program Files\nodejs\npm.cmd" install

cd /d C:\Users\Solomonm\Documents\Codex\2026-07-30\id-db\shared_budget
firebase functions:secrets:set OPENAI_API_KEY --project shared-budget-46538
firebase deploy --project shared-budget-46538 --only functions:analyzeTransaction
```

`functions:secrets:set` 명령이 값을 물으면 OpenAI Platform에서 만든 API 키를
입력합니다. API 키는 Flutter 코드, `.env`, Git에 저장하지 않습니다.

### 검사

```cmd
dart analyze lib test
"C:\Program Files\nodejs\node.exe" --check functions\index.js
```
