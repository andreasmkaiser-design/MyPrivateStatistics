# 19. TextEditingController (and ChangeNotifier) Lifecycle Ownership

Date: 2026-05-08
Status: accepted

## Context

Two separate bugs (issues #26, #29) shared the same root cause: a
`TextEditingController` was instantiated inside `build()` of a
`StatelessWidget`. Because `build()` runs on every state change, a new
controller was created on every keystroke:

```dart
// ❌ WRONG — new controller on every build
TextField(
  controller: TextEditingController(text: draft.name),
  onChanged: (v) => onChanged(draft.copyWith(name: v)),
)
```

Symptoms observed:
- **Reversed characters** on German keyboards — the IME (Input Method Engine)
  stores composition state in the controller; a new controller discards that
  state mid-composition, causing characters to be inserted in the wrong order.
- **Focus loss on Backspace** — Flutter detects the controller reference changed
  and re-attaches the text input connection, which resets focus.
- **Cursor jumping to end** — the new controller is initialised with the full
  text, so the cursor is always at position `text.length`.

The same problem applies to any `ChangeNotifier`-based Flutter object whose
identity must be stable across rebuilds: `FocusNode`, `ScrollController`,
`PageController`, `AnimationController`, `TabController`.

## Decision

**Any object that must survive a `build()` call must be owned by a `State`.**

### Rule 1 — never construct in `build()`

Never pass a freshly constructed `TextEditingController` (or similar) as a
widget property inline in `build()`. If a `StatelessWidget` needs one, convert
it to a `StatefulWidget`.

### Rule 2 — create in `initState`, dispose in `dispose`

```dart
class _MyState extends State<MyWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Rule 3 — sync via `didUpdateWidget` without disrupting composition

When the parent can change the logical value independently of what the user is
typing (e.g. an external reset), sync the controller in `didUpdateWidget`.
Guard with a value-equality check so normal keystrokes — which update both the
controller and the prop simultaneously — do not trigger an unnecessary sync
that would discard in-progress IME composition:

```dart
@override
void didUpdateWidget(MyWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.value != widget.value &&
      _controller.text != widget.value) {
    _controller.text = widget.value;
  }
}
```

For numeric fields where the prop is a parsed type (`double?`) and the
controller text is the raw string, compare the parsed value to avoid
reformatting a valid intermediate string (e.g. `'5'` → `'5.0'`):

```dart
if (oldWidget.min != widget.min &&
    double.tryParse(_controller.text) != widget.min) {
  _controller.text = widget.min != null ? widget.min.toString() : '';
}
```

### Rule 4 — the linter does not catch this

`very_good_analysis` does not have a rule that flags controller construction
inside `build()`. Prevention relies on code review and this ADR.

## Consequences

### Positive
- IME composition is never disrupted — correct input on all keyboard layouts.
- Focus and cursor position are stable across rebuilds.
- Memory is deterministic — one controller per field, disposed with the widget.

### Negative
- Every widget with a text field must be a `StatefulWidget`, adding a small
  amount of boilerplate.
- `didUpdateWidget` guards require careful thought when props and controller
  text use different types (see Rule 3 numeric case above).

### Risks
- If `didUpdateWidget` is omitted, an external value change (e.g. a form reset)
  will not be reflected in the text field — but this is a functional gap, not a
  crash, and is easy to notice in testing.

## References

- Flutter docs: [Using a TextEditingController](https://docs.flutter.dev/cookbook/forms/text-field-changes)
- GitHub issue #26 — fix in `CategoryFormScreen`
- GitHub issue #29 — fix in `FieldEditorRow` and `_ConstraintEditor`
- ADR-0013 (Dart Linting) — linting context; this pattern is not lint-enforced
- ADR-0012 (Full Test Pyramid) — widget tests for each text field verify
  focus retention and value persistence across rebuilds
