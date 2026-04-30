# Capitalo

Idle pixel tycoon mobile game. Marketing-driven core loop (zamiast tap-to-collect odpalasz kampanie z roll success/viral/fail). Target: iOS + Android, polski + EN markets, casual gracze 25-45 lat.

**Engine**: Godot 4.3+ (mobile renderer). **Language**: GDScript. **Status**: Pre-production complete, Sprint 1 ready.

## Project structure

- `project.godot` — Godot config, autoloady, display, input
- `scenes/` — `.tscn` sceny (`main/`, `city/`, `ui/`, `tutorial/`)
- `scripts/autoload/` — globalne singletony, ZAWSZE komunikacja przez EventBus
- `scripts/classes/` — reusable classes (BigNumber, ShopData, ...)
- `scripts/utils/` — helpers (Formatters, DataLoader)
- `data/` — JSON game data, **read-only** w runtime (shops, managers, campaigns, tech_tree)
- `assets/` — sprites/audio/fonts/palettes, **nie edytować** (generowane externally przez SD + Aseprite)
- `tests/` — GDScript unit tests (BigNumberTest, ...)
- `docs/` — wiedza projektowa, **nie kod**

## Key docs

- @docs/Capitalo_GDD.md — pełny GDD v1.0 (1233 linii, 17 sekcji), source of truth dla mechaniki
- @docs/architecture.md — decyzje techniczne, autoload boundaries, BigNumber, save versioning
- @docs/roadmap.md — milestones M1–M5 z phase 1-4
- @docs/STYLE_GUIDE.md — pixel art style guide, paleta, dimensions, animations
- @docs/LOGO_SPEC.md — logo spec + ASO + social media assets
- @docs/Capitalo_Economy_v1.xlsx — 986 formuł, kalibracja progresji, balans
- README.md — quickstart + krótki overview architektury

## Build & test

- Otwórz `project.godot` w Godot 4.3+ → F5 odpala `scenes/main/Main.tscn`
- Headless test: `godot --headless --script tests/BigNumberTest.gd`
- Lint: `gdlint scripts/` (gdtoolkit), Format: `gdformat scripts/`
- Save lokalizacja: `user://savegame.json` (pretty JSON), backup: `user://savegame_backup.json`

## Conventions — GDScript

- Tab indent (Godot default), snake_case dla funkcji/zmiennych, PascalCase dla klas/sygnałów
- `class_name` ZAWSZE na klasach reusable (żeby działał typing)
- Static typing wszędzie gdzie się da: `var x: int = 0`, `func foo(a: BigNumber) -> BigNumber:`
- Sygnały deklarujemy w EventBus, nie w nodach (centralizacja)
- Każdy ważny event przechodzi przez EventBus — **NIGDY direct refs między autoloadami/scenami**
- Wszystkie operacje arytmetyczne BigNumber **zwracają nową instancję** (immutable). Nie modyfikuj self.
- Pola dodawane do GameState **ZAWSZE** dorzuć do `to_dict()` ORAZ `from_dict()` — inaczej save się sypie
- BigNumber pola w save: użyj `bignumber.to_dict()` / `BigNumber.from_dict()` (nie raw float!)
- UI nie czyta GameState bezpośrednio — subskrybuje sygnały EventBus
- Tap targets minimum 44x44 px (mobile)

## Workflow

- Branch: `feat/`, `fix/`, `chore/`
- Commits: Conventional Commits, **subject EN**, body PL OK
- Plan mode (Shift+Tab ×2) przed każdą feature, potem acceptEdits
- TDD dla `scripts/classes/` i `scripts/utils/` — test first, see fail, implement
- `/feature <opis>` → Explore→Plan→Implement
- `/commit` → staged + Conventional Commit
- Po większej sesji: `/clear`

## Gotchas

- `float` w GDScript pęka na 10^100+. Idle game = ZAWSZE `BigNumber` dla money/income/cost
- Income tick = 0.1s w EconomyManager. Nie zmieniaj bez sprawdzenia balance impact
- Offline earnings cap = 8h (GDD §12.2). Cap to player respect, nie tech limit
- Auto-save co 30s. Manual save przy: app pause, scene change, prestige
- `res://` paths case-sensitive na Android, OK na iOS/desktop. Trzymaj snake_case w plikach
- Aseprite `.aseprite` w `assets/sources/` to sources, do gry idzie tylko PNG
- Mobile renderer: NIE używaj 3D shaderów / GI / SDFGI
- `EventBus.signal_name.emit()` — nie zapomnij `.emit()`, w Godot 4 to nie keyword

## Out of scope (do not add unless asked)

- Online/multiplayer w Phase 1 (lokalne save tylko)
- Ads / IAP w Phase 1 (Phase 2 → AdMob, Phase 3 → premium IAP)
- Cloud save w Phase 1-3 (Phase 4 Live Ops)
- Web export (mobile only target)
- C# scripts (GDScript only do Phase 4)

## Prompts hint

Mów po polsku w body promptów OK, ale code/commits/error messages **EN**. Krótkie sesje, jeden cel per session, `/clear` między.
