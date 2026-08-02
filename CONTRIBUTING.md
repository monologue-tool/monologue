# Contributing to Monologue

Thanks for wanting to help. This page covers what you need to run the editor, run the
tests, and get a pull request merged.

## Running the editor

```bash
git clone https://github.com/monologue-tool/monologue.git
```

Open the folder in Godot and press F5. There is no build step and no dependency to
install; `addons/` is vendored.

## Running the tests

Tests use [gdUnit4](https://github.com/MikeSchulze/gdUnit4) and live in `unit/`.

```bash
addons/gdUnit4/runtest.cmd -a unit
```

On Linux and macOS use `runtest.sh` instead. You can also run a suite from Godot's own
test panel once the gdUnit4 plugin is enabled.

Tests are headless: they build a `MonologueProject` and assert on the model directly,
without opening a window. If a change needs the scene tree to be tested, it usually
wants to move into the model first.

## Formatting and linting

**Run `gdlint`, never `gdformat`.**

```bash
pip install "gdtoolkit==4.*"
gdlint $(git ls-files '*.gd' | grep -v '^addons/')
```

`gdlint` is the gate, and CI runs exactly that command. `gdformat` is deliberately not
used: property declarations are written one option per line so the shape of a property
is readable at a glance, and `gdformat` collapses any chain that fits on one line with
no way to opt out.

```gdscript
define_property(Property.new("speaker/speaker")
    .set_type("reference")
    .reference_scope("characters")
    .label_property("name"))
```

Indentation and line length come from [`.editorconfig`](.editorconfig): tabs, 100
columns. Linter settings live in [`.gdlintrc`](.gdlintrc).

## Git

A bulk reformat is in the history and would otherwise drown `git blame`:

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

Branch names are `type/short-description`, for example `fix/dropdown-loses-speaker` or
`feat/reference-field`. Anything readable is fine; `wip/` is used for long-running work.

## Pull request checklist

- [ ] `gdlint` passes on every file you touched
- [ ] `runtest.cmd -a unit` passes
- [ ] New behaviour has a test; a bug fix has a test that fails without the fix
- [ ] No `gdformat` run snuck in — check the diff for unrelated reflowing
- [ ] Comments describe what the code does, not what you changed. Change rationale
      belongs in the commit message

## Two things that trip everyone up

### `value_changed` vs `value_committed`

Every field widget emits two signals, and picking the wrong one is the most common bug
in the UI layer:

- **`value_changed`** — the user is still typing. Fires on every keystroke, drag and
  slider move. Used for live feedback only. It does **not** write to the model and does
  **not** create an undo step.
- **`value_committed`** — the user is done: Enter, focus lost, item selected, drag
  ended. This is the only signal that writes, and it is one undo step.

Validation follows the same split. It **annotates, it never blocks** — a value the user
typed is always written, and what comes back is a description of what is wrong with it.
Reverting a value because a rule failed is how the editor used to silently eat input.

### `collection` vs `list`

Both render as a list of rows, and they are not the same thing.

|  | `list` | `collection` |
|---|---|---|
| Holds | plain values (strings, numbers) | full objects with their own properties |
| Item shape | whatever `item_type` says | a registered `CollectionItem` type |
| Items have ids | no | yes, and other things can reference them |
| Example | `editor_version` | a character's portraits, a choice node's options |

If items need to be pointed at from elsewhere, it is a `collection`.

## Where to start

Good first contributions, roughly in order of how self-contained they are:

- **Node types** — the runtime in `addons/monologue/core/process_logic/` implements
  more node types than the editor does. Each missing one is a self-contained task:
  add `common/nodes/<name>_node/` with an `index.gd` and the node script, then one
  `preload` line in `common/plugins/core/core_plugin.gd`.
- **Field types** — same shape, under `common/fields/<name>/`, plus a `.tscn` for the
  widget.

Open an issue before starting anything large, so nobody duplicates work.
