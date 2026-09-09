# VAMOS OPS Mobile

Flutter staff app for attendance, assigned/personal tasks, evidence, reports, and handover. GetX provides state, dependency injection, and navigation. It consumes the dashboard's existing `/api/v1` contract.

## Structure

```text
lib/main.dart                   Process entry point
lib/app/vamos_app.dart          GetMaterialApp configuration
lib/app/bindings/               Application-wide service registration
lib/app/routes/                 Route names and page registration
lib/app/core/                   Config, errors, cache, device services, storage, theme
lib/app/data/models/            Shared page, area, home, and performance models
lib/app/data/providers/         Authenticated transport and response decoding
lib/app/data/repositories/      Injection contracts and aggregate API implementation
lib/app/widgets/                Shared UI, feedback, pagination, evidence photos
lib/app/modules/auth/           Authentication provider/repository/controller/views
lib/app/modules/staff/          Staff binding, shell, home and mutation coordination
lib/app/modules/home/           Home screen and summary widgets
lib/app/modules/tasks/          Task models, query controller, views/forms/widgets
lib/app/modules/reports/        Report models, query controller, views/forms/widgets
lib/app/modules/attendance/     Attendance card and handover sheet
lib/app/modules/profile/        Profile and app-settings views
test/support/                   Shared fake repositories, camera, and task fixture
```

The provider handles HTTP; the repository decodes API responses behind injectable contracts; controllers own reactive state; views render it. Feature files use direct package imports. Keep private widget State classes beside their widget and expose sheet entry functions instead of a shared Dart `part` library.

`TaskListController` owns task period selection, pagination, and list cache. `ReportListController` owns report pagination/detail cache. `StaffController` owns home aggregates and operations that coordinate tasks, attendance, evidence, and reports. It exposes the collaborators' existing reactive values without copying them and disposes them with the staff session. This keeps optimistic updates, rollback, generation guards, and cache behavior consistent.

`AppBinding` registers permanent infrastructure. `StaffBinding` registers route-level staff state. Both retain injectable contracts for tests. Shared HTTP response decoding and DTO parsing belong to the data layer, not widgets.

## Development

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

The example targets an Android emulator. For an iOS simulator use `http://localhost:3000/api/v1`. For a physical phone, supply the dashboard computer's reachable LAN address. Verify the dashboard's `/api/health` endpoint from the device first. Release deployments require HTTPS.

The backend is maintained in [vamos-ops-dashboard](https://github.com/VincentiusKennedyW/vamos-ops-dashboard). In the integrated workspace, the shared API contract lives at `../../packages/contracts/openapi.yaml` and architecture documentation at `../../docs`.

## Verification

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Tests cover authentication, device-service injection, widgets, task/report interactions, pagination, request counts, cache behavior, and optimistic rollback. Shared fixtures live under `test/support`; test suites do not import another test suite.

For device acceptance: sign in, clock in with selfie/location, change task period/status, paginate, start/complete a task with evidence, create a report, open its detail, and clock out. Verify explicit refresh and logout clear the expected session state. The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.
