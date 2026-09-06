# Antigravity Flutter Agent Guidelines

## 1. Project Context & Stack Defaults
- **Framework**: Flutter (latest stable) / Dart SDK
- **Architecture**: Feature-first structure (`lib/src/features/<feature_name>/...`)
- **Layers**: `presentation/`, `domain/`, `data/`
- **Immutability**: Prefer immutable data models (`@freezed` or custom `copyWith` patterns)

## 2. CLI & Terminal Execution Rules
When executing bash or terminal commands in the agentic loop:
- **Never Run Blocking Commands**: NEVER execute `flutter run`, `flutter attach`, or any daemon process without background execution.
- **Code Generation**: Run `dart run build_runner build --delete-conflicting-outputs` immediately after creating or modifying generated models (`.g.dart`, `.freezed.dart`).
- **Validation Check**: Always run `flutter analyze` after modifying files to verify zero warnings or linter errors before completing a task.
- **Dependency Management**: Check `pubspec.yaml` before adding imports. Use `flutter pub add <package>` rather than editing `pubspec.yaml` manually when adding dependencies.

## 3. Flutter & Dart Coding Standards
- **UI & Layouts**:
  - Always use `const` constructors wherever possible.
  - Keep widgets small and modular. Prefer extracting sub-widgets into standalone `StatelessWidget` classes rather than helper builder methods (e.g., `_buildHeader()`).
  - Ensure responsive design using `LayoutBuilder` or `MediaQuery` abstractions.
- **State Management**:
  - Do not use raw `setState` for global or complex business logic.
  - Handle loading, error, and data states explicitly using sealed classes or pattern matching (`switch` expressions).
- **Error Handling**:
  - Never suppress errors with empty `catch` blocks.
  - Use explicit error domains (e.g., `Failure` classes) instead of throwing raw strings or dynamic exceptions.

## 4. Multi-File Edits & Refactoring
- Keep diffs surgical. Do not touch untouched files or reformat existing code unless requested.
- When creating a new feature:
  1. Define domain entities/contracts.
  2. Implement data layer / API providers.
  3. Wire state management logic.
  4. Build UI widgets.
  5. Run `flutter analyze` to confirm clean integration.