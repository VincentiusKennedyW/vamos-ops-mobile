# VAMOS OPS Mobile

- Flutter + GetX staff client of the dashboard `/api/v1` API. Preserve compatibility with that shared contract.
- Follow feature ownership and data flow described in README.md. Place new screen/form/model code in its owning module.
- Preserve one owner per reactive value. StaffController coordinates cross-feature mutations; task/report list controllers own query state.
- Preserve session cache clearing, generation guards, request counts, optimistic reconciliation/rollback, and explicit refresh behavior.
- Store timestamps in UTC; operational dates come from the venue-aware API. Keep task occurrences independent.
- Keep camera/location/storage behind injectable contracts. Retain binding lifecycle and route names.
- Use direct package imports across modules. Keep a widget's private State in the same file.
- Run flutter analyze and flutter test for changes; build the Android debug APK when validating app packaging.
- Platform projects, assets, and generated files are not structural refactoring targets. Never commit secrets or build output.
