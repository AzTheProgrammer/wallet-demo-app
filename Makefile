.PHONY: setup test coverage

setup:
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs

test:
	flutter test

coverage:
	flutter test --coverage
	flutter pub run tool/coverage_report.dart
