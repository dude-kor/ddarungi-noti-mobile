# 따릉이 알리미 – Flutter client

Flutter app (Riverpod, Dio, Kakao Map) for the 따릉이 알리미 service: onboarding, permission pre-prompt, map with a
station sheet, chosung search, alert setup and favourites. It talks to the Spring Boot service in the
`ddarungi-noti-backend` repository – the REST contract lives in that repository's `docs/API.md`.

**Not wired yet:** the push token. `PlaceholderPushTokenProvider` registers `dev-<deviceToken>` so the API works, but no
real push arrives until `firebase_messaging` is added (see `lib/core/push/push_token_provider.dart`).

## Run locally

1. Start the backend (`docker compose up -d` and `./gradlew bootRun` in the backend repository).
2. Generate and patch the native projects once (needs the Flutter SDK):

   ```bash
   CLEARTEXT=1 bash scripts/setup_platforms.sh     # android/ + ios/, permissions, http:// allowed for local dev
   flutter pub get
   ```

3. Run:

   ```bash
   flutter run \
     --dart-define=API_BASE_URL=http://10.0.2.2:8080 \
     --dart-define=KAKAO_JS_KEY=<Kakao JavaScript key>
   ```

   `10.0.2.2` is the host machine as seen from the Android emulator; use `http://localhost:8080` on the iOS simulator.

`scripts/setup_platforms.sh` runs `flutter create` when `android/` or `ios/` is missing, then idempotently adds the
Android permissions (INTERNET, location, notifications) and the iOS location usage text. Those folders are git-ignored
because they are fully generated; remove `/android/` and `/ios/` from `.gitignore` and commit them as soon as you
customise native code (for example a release signing config).

Other setup:

- **Kakao**: register the app's platforms and web domain in Kakao Developers; `kakao_map_plugin` needs the *JavaScript key*.
- **Font**: download Pretendard into `assets/fonts/` and uncomment the `fonts:` block in `pubspec.yaml`.

## Tests

```bash
flutter analyze
flutter test
```

## CI/CD (GitHub Actions)

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | push to `main`, pull requests | `flutter analyze` + `flutter test` · debug APK (artifact, 7 days) · iOS build without code signing (`main` and manual runs only – macOS minutes are expensive) |
| `release.yml` | tags `v*.*.*`, manual | release APK attached to a GitHub Release |

Configure in *Settings → Secrets and variables → Actions*:

| Name | Kind | Used by | |
|---|---|---|---|
| `KAKAO_JS_KEY` | secret | CI, release | release fails fast when missing |
| `API_BASE_URL` | variable | CI, release | CI falls back to `http://10.0.2.2:8080`; release requires an `https://` URL |

The release APK is signed with the **debug key** until you add an upload keystore – fine for internal testing, not for
Google Play. Dependabot keeps pub packages and GitHub Actions current.

## Layout

```
lib/
  main.dart                 Kakao init, ProviderScope, routing
  core/
    config/                 --dart-define values
    theme/                  AppColors, AppTypography, AppTheme (44px touch, 52px CTA)
    network/                Dio + X-Device-Token interceptor, ApiFailure, ApiGuard (re-register on 401)
    storage/, push/, location/, router/, map/, utils/ (HangulUtils)
  features/
    onboarding/             SCR-01, SCR-02
    station/                SCR-03 map + sheet, SCR-04 search
    schedule/               SCR-05 alert setup
    favorites/              SCR-06
    device/                 POST /devices registration
scripts/setup_platforms.sh  generates + patches android/ios
```
