# Testing

## Strategy

| Kind | Where | Covers |
| --- | --- | --- |
| Unit | `test/core`, `test/features/**` | Use cases, repositories, mock data sources, validators and money, including failure paths |
| Bloc | `test/features/**` with `bloc_test` | State transitions for every Bloc and Cubit |
| Widget | `test/core/widgets_test.dart`, `*_page_test.dart`, `*_pages_test.dart` | Loading, success, empty and error states, plus key interactions |
| End to end | `integration_test/happy_path.dart` | Set up a PIN, send money, see it in history |

Mocks use `mocktail`. Shared fixtures, mocks and pump helpers are in `test/helpers`.

The happy path runs on a device through `integration_test/app_test.dart`, and on the host through `test/app/happy_path_test.dart`, so it runs on every CI build.

## Running

```bash
flutter test
```

```bash
make coverage
```

```bash
flutter test integration_test -d <device>
```

Coverage should stay above 90% on the domain and presentation layers. `make coverage` leaves generated files out and writes the report to `coverage/index.html`.

## Goldens

Golden tests are disabled for now. They are commented out in `test/goldens/screens_golden_test.dart`.

## README screenshots

`test/screenshots` drives the real app with real fonts and writes the images to `docs/screenshots`. It is skipped in normal runs:

```bash
flutter test test/screenshots --dart-define=SCREENSHOTS=true --update-goldens
```
