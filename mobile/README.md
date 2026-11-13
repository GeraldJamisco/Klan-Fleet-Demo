# Klan Fleet: mobile app (Flutter)

Driver and fleet-manager app for the demo fleet API. One codebase for Android, iOS, Windows and web.

**Honest status:** the code was written and syntax-checked, but I could not compile Flutter where it was written.
Expect to run `flutter analyze` once and fix anything it reports (usually a few minutes of work).

## One-time setup (Windows)

1. Install Flutter: https://docs.flutter.dev/get-started/install/windows/mobile (follow "Android" if you want a phone/emulator).
   Add `flutter\bin` to PATH, then open a new terminal.
2. Run `flutter doctor`. Accept Android licences if asked: `flutter doctor --android-licenses`.
   You already have Android tooling on this computer (`.android`, `.gradle`), so this is usually quick.
3. In this `mobile` folder, generate the platform folders (this does **not** overwrite `lib/`):

   ```
   flutter create --project-name klan_fleet_mobile --platforms=android,windows,web .
   flutter pub get
   flutter analyze
   flutter test
   ```

   If `flutter analyze` reports problems, send me the output and I will fix them.

## Allow the app to talk to the demo server over HTTP (Android only)

The demo API is plain `http://` on your own network. Android blocks that by default, so open
`android/app/src/main/AndroidManifest.xml` and make two small edits:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />   <!-- add this line -->
    <application
        android:usesCleartextTraffic="true"                          <!-- add this attribute -->
        ... >
```

This is for the demo only. A real app would use HTTPS.

## Run it

Start the API first (see the root README), then:

| Where | Command | Server address on the login screen |
|---|---|---|
| Chrome (no phone needed) | `flutter run -d chrome` | `http://localhost:3000` |
| Windows desktop | `flutter run -d windows` | `http://localhost:3000` |
| Android emulator | `flutter run` | `http://10.0.2.2:3000` (default) |
| Real Android phone | enable USB debugging, `flutter run` | `http://<laptop Wi-Fi IP>:3000` |

For a real phone: laptop and phone must be on the same Wi-Fi. Find the laptop IP with `ipconfig` (IPv4 Address).
If it cannot connect, allow Node.js through Windows Firewall for private networks.

Demo logins (fake data): driver `0700000012` / `2222`, manager `0700000001` / `1234`.

## Build an APK to install on a phone

```
flutter build apk --release
```

The file is at `build\app\outputs\flutter-apk\app-release.apk`. Copy it to the phone and install it.
Make sure you added the INTERNET permission above, or the release build cannot reach the server.

## How the code is organised

```
lib/
  main.dart                  App entry, picks login / driver app / manager console from the session
  core/
    api_client.dart          REST client: bearer token, timeout, errors turned into friendly messages
    session.dart             Login state, saved on the device, server address
    models.dart              Typed models parsed from the API's JSON
    format.dart              Pure helpers (money, dates, status flow), unit tested
  screens/
    login_screen.dart        Server address + phone + PIN, demo account shortcuts
  widgets/common.dart        Shared pieces of the login screen
  console/                   Manager console (Material 3, ported from the Nexora prototype)
    core/access.dart         Roles, modules and the permission matrix (pure Dart, unit tested)
    models/ops_models.dart   API-ready models with fromJson / toJson
    data/                    ConsoleRepository interface, demo implementation, API implementation
    state/                   ConsoleController (role, module, data source), ThemeController
    theme/console_theme.dart Light and dark colours as a ThemeExtension (`context.cc`)
    widgets/                 Reusable parts: KPI card, chart, map, table, chips, buttons, inputs
    shell/console_shell.dart Role-based navigation: sidebar, icon rail or phone bottom bar
    screens/                 Overview, trips (+ detail, new trip), fleet, drivers, fuel, safety,
                             depot, reports, ERP, settings
  driver/                    Driver app (same theme and widgets)
    models/ data/ state/     Models, DriverRepository (demo + API), DriverController
    widgets/                 Trip cards, status / fuel / issue / proof-of-delivery forms
    shell/driver_shell.dart  Sidebar on wide screens, five-tab bottom bar on phones
    screens/                 Home, my trips, trip navigation, documents, fuel, messages, profile
test/                        Unit and widget tests (helpers, access matrix, repositories, shells)
```

Managers (`role: manager`) land in the console, every other role in the driver app. Both can switch between
**Demo data** (offline, same every time) and **Live API** (trips, status updates, fuel, incidents, ERP).
Screens the API does not serve yet show sample data and say so on the page.
In the console, a manager can also use *Settings → View as* to preview what each role sees.

State management is deliberately simple: `provider` for the session and the two controllers, plain `StatefulWidget`s
for filters and forms. Screens never talk to the network directly, only to a repository interface.

## Not built yet (good next steps, and honest answers if asked)

- Offline queue: drivers lose signal on highways. Queue status updates on the phone and send them when back online.
- GPS: send location with each status change (needs the `geolocator` plugin and permissions).
- Photo proof of delivery and signature capture (the proof form records receiver and confirmation only).
- Push notifications when a trip is assigned.
- Real map tiles (the maps are drawn illustrations) and real documents / messages endpoints.
- Integration tests against a running API.
