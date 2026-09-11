# CLAUDE.md — talkverselab/talkverse-mn

이 폴더에서 작업하는 모든 세션이 먼저 읽는 규칙. **빌드·배포를 건드리기 전에 반드시 확인할 것.**

## 1. 서명 (가장 자주 사고 나는 곳)

이 앱은 GitHub 릴리스로 **앱 안에서 스스로 업데이트**한다.
폰에 이미 깔린 앱과 **서명 키가 같아야만** 덮어쓰기 설치가 된다.

### 쓰는 키 — 새로 만들지 말 것

- 폰에 깔린 앱과 같은 키: 로컬 `~/.android/debug.keystore`
  (alias `androiddebugkey`, store/key 비밀번호 `android`)
- SHA-1 `9C:C4:BC:93:26:38:BE:43:A3:98:2D:F2:0B:71:C4:75:02:88:47:6B`
- 같은 키가 리포 시크릿 **`ANDROID_DEBUG_KEYSTORE_BASE64`** 에 base64로 들어 있고, CI가 이걸 복원해 서명한다.
- 로컬에서 릴리스 빌드할 때도 같은 키를 쓴다. `android/key.properties`가 없으면 이렇게 만든다:

```bash
cp ~/.android/debug.keystore android/app/signing-key.jks
printf 'storePassword=android\nkeyPassword=android\nkeyAlias=androiddebugkey\nstoreFile=signing-key.jks\n' > android/key.properties
```

### 절대 하지 말 것

- **새 키스토어를 만들지 말 것.** 서명이 바뀌면 폰에서 앱을 지웠다 다시 깔아야 하고, **학습 기록이 전부 사라진다.**
- CI의 `Restore signing key` 단계를 지우거나, `build.gradle.kts`의 release 서명을
  `signingConfigs.getByName("debug")` 로 되돌리지 말 것.
  GitHub 러너는 빌드할 때마다 debug 키를 **새로 만들어** 서명이 매번 달라진다.
  (2026-09-10에 실제로 겪은 문제 — 17개 앱 설치가 전부 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`로 실패했다.)
- `android/key.properties`, `android/app/signing-key.jks`를 커밋하지 말 것 (`.gitignore`에 있음).

### 설치가 실패하면

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: signatures do not match
```

→ 앱을 지우지 말고 **서명부터 확인**한다:

```bash
apksigner verify --print-certs <apk> | grep SHA-1   # 9cc4bc932638be43a3982df20b71c4750288476b 여야 한다
```

## 폰에 설치할 때 (PC에서 케이블로)

폰에 **듀얼 메신저 프로필(user 95)** 과 보안 폴더(user 150)가 있다. `adb install` 은 프로필을 지정하지 않으면
**모든 프로필에 설치**해서 앱 아이콘이 두 개(파란 말풍선 배지 달린 복제본)가 생긴다. 반드시 기본 프로필만 지정한다:

```bash
adb -s R3CY20HDN2K install --user 0 -r <apk>
```

(2026-09-11에 24개 앱이 전부 두 개씩 깔려 있던 것을 정리함. 앱 안의 「앱 업데이트」로 설치하면 이 문제는 생기지 않는다.)

## 2. 배포 흐름

- `master`(또는 기본 브랜치) 푸시 → GitHub Actions(`.github/workflows/release.yml`)가
  서명된 APK와 `latest.json`을 `latest` 릴리스에 올린다.
- **빌드 번호 = 워크플로 실행 번호**(`--build-number=${{ github.run_number }}`).
  앱은 자기 빌드 번호와 `latest.json`의 `build`를 견주어 새 빌드를 판단한다.
  로컬 `flutter build apk`로 만든 APK는 pubspec의 작은 번호를 써서 앱이 늘 "새 빌드 있음"으로 보인다 — 정상.
- `**.md`만 고친 푸시는 빌드하지 않는다(`paths-ignore`). 헛된 업데이트 알림 방지.
- **폰 업데이트**: 앱 → 설정(프로필) 화면 → **「앱 업데이트」** → 내려받아 설치. 케이블·adb 불필요.
  첫 설치 때 「출처를 알 수 없는 앱 설치」 허용이 한 번 필요하다(안드로이드 강제).

관련 파일: `lib/services/update_service.dart`, `lib/screens/update_screen.dart`,
`android/app/src/main/kotlin/**/MainActivity.kt`(설치 메서드 채널),
`android/app/src/main/res/xml/file_paths.xml`, `.github/workflows/release.yml`

구현 안내서: https://github.com/talkverselab/talkverse-th/blob/master/docs/in-app-update-via-github.md

## 3. 리포

- 이름은 **`talkverselab/talkverse-<언어코드>`** 로 통일(2026-09-10). 옛 이름(`mn-universe` 등)은 리다이렉트되지만
  remote는 새 이름으로 바꿔 둘 것: `git remote set-url origin https://github.com/talkverselab/talkverse-mn.git`
- **공개(PUBLIC) 저장소**다. 앱이 토큰 없이 APK를 받으려면 공개여야 한다.
- 다운로드 허브: https://github.com/talkverselab/talkverse-releases

## 4. 공개 저장소라서 지킬 것

- **출처를 드러내지 말 것.** 자막·말뭉치 제공처 이름(스트리밍 서비스, 공개 자막 데이터셋 등), 책 이름·쪽수,
  드라마·영화 제목을 코드·에셋·문서·파일명·화면 문구 어디에도 남기지 않는다.
- 저작권 있는 원문(자막 대본, 원서 전사)을 리포에 넣지 않는다. 단어·빈도 통계만 쓰고 문장은 자체 제작한다.
- 새 파일을 추가할 때 위 두 가지를 먼저 확인할 것. 한 번 공개 커밋되면 히스토리에 남는다.

## 2026-09-11 — es형 템플릿으로 재구축

이 앱은 `talkverse/de`(es형 템플릿)를 바탕으로 **다시 지었다.** 화면·DB·기능은 de·es·fr 등 8개 앱과 같다
(회화 · 문법 · 문장 카드 · 말하기 · 청크 검색 · 단어 · 표현 · 빈도 단어 · 단어 카드 · 앱 업데이트).

- **이전 코드·자산은 `talkverse/_legacy/mn/`** 에 그대로 있다(리포 밖). git 이력에도 남아 있다.
- 옮긴 콘텐츠: 몽골어 회화 2편(16턴) · 여행 데이팅 문장 250(표현 + 문법 2강) · 단계별 예문 22 · 기초 명사 50. **TTS 는 사전 합성 mp3(`assets/audio/`, 578개)** — 기기 TTS 에 몽골어가 없어 기존 `TtsService` 를 그대로 살렸다.
- 콘텐츠 이전 스크립트: `_update_kit/migrate_content.py`, 재구축: `_update_kit/rebuild_app.py`.
- 대상어 문장 칸 이름은 템플릿 그대로 `es` 다. 언어와 무관하게 "대상어"로 읽는다.
- 화면 코드는 8개 앱 공용 키트(`_update_kit/port6/`)에서 왔다. 고칠 일이 있으면 키트를 고쳐 다시 배포한다.
