# Nearzy — Flutter app

The Nearzy client. One binary serves all three roles: after the profile fetch on
launch, `main.dart` decides whether to open the customer, shop-owner or admin
home screen.

For what Nearzy is, the API and the backend setup, see the
[project README](../README.md).

## Toolchain

The Flutter version is pinned in [`.fvmrc`](.fvmrc) and **must** be run through
[fvm](https://fvm.app) — a bare `flutter` on your `PATH` is very likely a
different SDK:

```bash
fvm install            # first time only — installs 3.44.7
fvm flutter pub get
fvm flutter run
```

Model classes use `json_serializable`, so after editing anything in
`lib/data/models/` regenerate the `.g.dart` files:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

## Pointing at a backend

`baseApiUrl` in [rest_api_const.dart](lib/constants/rest_api_const.dart) is the
single switch; every other URL derives from it. The file ships with a reserved
ngrok domain and a commented-out `http://localhost:8080` line.

- **Simulator / emulator against a local backend** — use the `localhost` line.
- **Physical device** — `localhost` is the phone, not your laptop. Run
  `ngrok http 8080` and paste that URL.

Every request goes through [api_client.dart](lib/services/api_client.dart),
which attaches the access token, adds the header that skips ngrok's browser
interstitial, and on a `TOKEN_EXPIRED` refreshes once and replays the request.

## Structure

```
lib/
  constants/       API URLs, per-role bottom-nav definitions
  data/
    models/        DTOs (json_serializable)
    repositories/  Customer- and shop-side data access
  presentation/
    common/        Shared widgets, animations, screens
    features/      One folder per feature, split by role
  services/        API client, session, geolocation, Razorpay, Cloudinary
  theme/           Design tokens — colours, type, spacing, motion
  utils/           Extensions, exceptions, launch tasks
```

Features are grouped by role (`features/customer/`, `features/shop/`,
`features/admin/`) and larger ones follow `view/` + `view_model/` with a
`flutter_bloc` bloc as the view model.

## Design system

The app follows a documented visual language called **"Local Premium"** —
palette, type scale, spacing rhythm, motion tokens and component recipes all
live in `lib/theme/` and are specified in
[`.claude/skills/nearzy-design/SKILL.md`](../.claude/skills/nearzy-design/SKILL.md).

The short version: near-black ink on warm paper with lime as the only accent,
large radii, and nothing appears without an entrance animation. Read the skill
before building or restyling a screen — it exists so screens stay one product
rather than a pile of Material defaults.

Practical rules that bite most often:

- No hardcoded colours, text styles, radii or durations — everything comes from
  `AppColors` / `AppTextStyles` / `AppSpacing` / `Motion`.
- Network images go through `NearzyNetworkImage` (disk cache, shimmer
  placeholder, styled fallback), never a raw `Image.network`.
- In-app navigation uses `NearzyPageRoute`, not `MaterialPageRoute`.
- Check `lib/presentation/common/widgets/` before building a component; there is
  probably already one.

## Tests

```bash
fvm flutter test
```

| Test | Covers |
|---|---|
| `auth_session_test.dart` | Parsing a session out of a server response, and staleness |
| `session_refresh_test.dart` | Token refresh and request replay — **against a live backend** |
| `location_screens_test.dart` | Build tests for the location picker and map surfaces |
| `verification_swipe_test.dart` | Admin verification swipe → decision mapping |
| `cross_fade_test.dart` | `CrossFade` keying (skeleton → content) |
| `widget_test.dart` | App shell smoke test, via the onboarding path |

`session_refresh_test.dart` drives the real `SessionManager` and `NearzyHttp`
against a running server instead of a stub that always says yes. It skips
itself when nothing is listening on `baseApiUrl`, so the suite still passes
with no backend up — to actually run it, start the backend first:

```bash
cd backend && npm run dev
cd frontend && fvm flutter test test/session_refresh_test.dart
```
