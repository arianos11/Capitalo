# Capitalo — Pixel Art Style Guide v1.0

> Ten dokument jest **źródłem prawdy** dla wszystkich assetów wizualnych w grze Capitalo.
> **Każdy asset musi przejść checklistę z sekcji 7 przed dodaniem do gry.**

---

## 1. Filozofia wizualna

### 1.1 Pryncypia

1. **Spójność > Detal.** Lepiej mieć 80 sprite'ów w identycznym stylu niż 80 z różnymi paletami.
2. **Czytelność na małym ekranie.** Gra jest mobilna — sprite musi być rozpoznawalny w 32x32 px na 6" telefonie.
3. **Retro = ograniczenia jako feature.** Pixel art żyje z **disciplined constraints**: ograniczona paleta, brak anti-aliasingu, ograniczone klatki animacji.
4. **Charakter > Realizm.** Postacie i sklepy mają mieć **osobowość** — nawet manager Sara Couture ma byc rozpoznawalna w 64x64 px.
5. **Każdy pixel ma znaczenie.** W 32x32 nie ma miejsca na "filler" — każdy pixel decyduje o czytelności.

### 1.2 Wpływy / inspiracje

| Gra | Co bierzemy |
|-----|-------------|
| **Stardew Valley** | Top-down view miasteczka, building proportions, palette warmth |
| **Shovel Knight** | UI elements, precyzja outlines, czytelność w małej skali |
| **Owlboy** | Jakość animacji, feel klatek animacji |
| **Eastward** | Kolory tła, lighting w nocy/dzień |
| **AdVenture Capitalist** | Layout HUD, floating numbers feel |
| **Idle Miner Tycoon** | Building level progression visual cues |

### 1.3 Czego NIE chcemy

- ❌ Generic AI-generated pixel art (rozpoznawalny po anti-aliasingu i niespójnej palecie)
- ❌ Style imitujący Cookie Clicker / Cookie Run (zbyt cute, infantilny)
- ❌ HD-2D (Octopath Traveler) — za drogi w produkcji
- ❌ Voxel / 3D rendered pixel — łamie retro feel
- ❌ Anime aesthetic — niespójne z business/retail theme

---

## 2. Master Palette (30 kolorów)

### 2.1 Reguła #1: ZAWSZE z palety, NIGDY pośrednie tony

Cała gra używa **30 zdefiniowanych kolorów** zorganizowanych w 8 grup. **Żaden asset nie może wprowadzać kolorów spoza palety**, nawet "podobnych".

**Pliki palety w folderze:**
- `capitalo_master_palette.svg` — wizualizacja do podglądu
- `capitalo_master_palette.json` — programatyczne użycie
- `capitalo_master_palette.gpl` — import do Aseprite (GIMP Palette format)

### 2.2 Grupy kolorów i ich zastosowanie

#### Neutrals (6 kolorów)
- `#0F0F1B` Deep Black — outline KAŻDEJ postaci i budynku (1 px), cienie głębokie
- `#1D2B53` Dark Navy — cienie tła, sceny nocne
- `#3F3F74` Slate Purple — midtone cienie postaci
- `#5F574F` Warm Gray — alternative outline (gdy czarny jest za mocny)
- `#94B0C2` Cool Gray — UI panels, neutral elements
- `#FFF1E8` Cream White — highlights, najjaśniejsze tła UI

#### Browns (4 kolory)
Drewno, kartony, paczki, podłogi sklepów
- `#3E2C29` / `#7E4427` / `#C18556` / `#E8C580` (shadow → highlight)

#### Reds (3 kolory)
Fashion shop accent, sale tags, alerts, hot items
- `#7A1E29` / `#D8334A` / `#FF7A8A`

#### Oranges/Yellows (4 kolory)
Food shop, **coins/money** (najważniejsze!), highlights
- `#A8530F` / `#E89B3F` / `#FFCB45` (główny kolor monet) / `#FFE872` (sparkle highlight)

#### Greens (3 kolory)
Trawa, sports, **money positive indicators** (zarobki)
- `#1E5A3A` / `#3CA858` / `#8FE38A`

#### Blues (3 kolory)
Tech shop, niebo, water, glass
- `#1A4A8C` / `#2E7BD1` / `#6FC3E0`

#### Purples (3 kolory)
Beauty/luxury shops, magic effects, viral indicators
- `#4A1B5C` / `#8E3FB0` / `#D387D9`

#### Special (4 kolory)
- `#FF004D` Hot Pink — **VIRAL!** alerts, rare events
- `#00E0F0` Cyan — automation/AI glow, tech accents
- `#FFB000` Amber — toys shop, achievements
- `#5BC15B` Cash Green — $$$ amounts, profit

### 2.3 Zasady mieszania kolorów

**Shading rule (3 tones per object):**
- Shadow (najciemniejszy z grupy)
- Midtone (środkowy)
- Highlight (najjaśniejszy)
- + Outline (zawsze `#0F0F1B` lub `#5F574F`)

**Ramp examples:**
- Wood: `#3E2C29` → `#7E4427` → `#C18556` → `#E8C580`
- Money/gold: `#A8530F` → `#E89B3F` → `#FFCB45` → `#FFE872`

**NIGDY** nie mieszamy kolorów z różnych grup w jednym obiekcie (np. niebieski cień + zielony midtone). Cały obiekt = jedna grupa kolorów + Neutrals na outlines.

---

## 3. Wymiary i siatka

### 3.1 Standardy wymiarowe

| Asset | Rozmiar | Notes |
|-------|---------|-------|
| **Małe ikony UI** | 16x16 px | Currency, particles, small icons |
| **UI buttons** | 32x16 lub 48x16 | Width zależy od long text |
| **Standardowe budynki sklepów (Lvl 1)** | 32x32 px | Małe sklepy startowe |
| **Średnie budynki (Lvl 2)** | 48x48 px | Po pierwszym upgrade |
| **Duże budynki (Lvl 3)** | 64x64 px | Po drugim upgrade — dominują scenę |
| **Klienci (NPCs)** | 16x24 px | Pionowy prostokąt — 16 wide, 24 tall |
| **Manager portraits** | 64x64 px | Do shop detail modal, hire screen |
| **Manager walking sprites** | 24x32 px | Do animacji ruchu po mieście |
| **Player avatar** | 32x40 px | Gnome przedsiębiorca |
| **Tile background** | 16x16 px | Trawa, chodnik, ulica |
| **Particles (coins, stars)** | 8x8 lub 16x16 | Pool reusable |
| **Logo (in-game)** | 128x128 px | Splash screen, menu |
| **App icon** | 1024x1024 (target export) | Skalujemy z 128x128 master |

### 3.2 Reguła siatki

**Cała gra renderuje na siatce 16x16 px.** Wszystkie pozycje obiektów są multiples of 8 lub 16.

Pixel scale w grze: **3x** (każdy "logiczny" pixel = 3x3 fizycznych pikseli na ekranie). Czyli sprite 32x32 wyświetla się jako 96x96 na ekranie. Dla iPhone 14 Pro (393x852 logical pts), to oznacza ~12 sprite'ów na szerokość — komfortowo czytelne.

### 3.3 Pixel art rule: NO ANTI-ALIASING

- **Każdy pixel ma być twardy** — albo kolor X, albo kolor Y, nigdy "mid"
- W Aseprite: ustaw **Filter: Nearest neighbor** zawsze
- Stable Diffusion: dodaj `no anti-aliasing` do negative prompt
- Po AI generation: **zawsze** cleanup w Aseprite (paint bucket z 0% tolerance, fix anti-aliased pixels)

---

## 4. Asset Categories — szczegółowe wytyczne

### 4.1 Budynki sklepów

**Każdy sklep ma 3 wizualne levele**:
- **Lvl 1** (32x32) — mały sklep, 1 piętro, prosty fasada
- **Lvl 2** (48x48) — 2 piętra, znacznie więcej detali, neon sign
- **Lvl 3** (64x64) — wieżowiec/megastore, najbardziej imponujący

**Visual progression rules:**
1. Sklep tej samej kategorii zachowuje **brand color** przez wszystkie 3 levele
2. Lvl 2 dodaje: neon, więcej okien, więcej szczegółów
3. Lvl 3 dodaje: signage z brandem, klientów na zewnątrz, special elements (np. Tech Lvl 3 ma drone na dachu)

**Color usage per kategoria** (z shops.json):
- Fashion: `#D8334A` primary, `#FF7A8A` accent
- Tech: `#2E7BD1` primary, `#00E0F0` accent (cyan tech)
- Food: `#E89B3F` primary, `#FFCB45` accent (gold trim)
- Home: `#7E4427` primary, `#C18556` accent (woody)
- Beauty: `#8E3FB0` primary, `#D387D9` accent
- Books: `#1A4A8C` primary, `#6FC3E0` accent
- Toys: `#D8334A` + `#FFB000` (multi-color)
- Sports: `#3CA858` primary, `#1E5A3A` shadow
- Luxury: `#FFCB45` (złoto) + `#0F0F1B` (czarny chrom)
- Marketplace: `#0F0F1B` + `#FFCB45` (premium dark)

### 4.2 Klienci (NPC sprites)

**16x24 px** to standard. Kategorie klientów:

1. **Casual shopper** (default): plain clothes, walks at 1 px/frame
2. **Premium shopper**: better clothes (luxury palette colors), walks slower (więcej zysku)
3. **Kid/Teen**: smaller sprite (16x20), faster walk, hangs out near Toys
4. **Senior**: gray hair, slower walk, prefers Books and Home
5. **Influencer**: phone in hand, sparkle effect, spawns during viral hits

**Animation:** 4-frame walk cycle (left foot down → mid → right foot down → mid)

**Skin tones:** zawsze użyj jednego z palette (np. `#C18556` jako tan skin, `#E8C580` jako fair, `#7E4427` jako brown, `#3E2C29` jako dark). **Nie wprowadzaj nowych kolorów dla skin tones.**

### 4.3 Manager portraits (64x64)

Każdy manager ma:
- **Portrait** (64x64) do hire screen i shop detail
- **Walking sprite** (24x32) do animacji w mieście
- **Iconic accessory** identifying ich (np. Sara = czarny beret, Marco = chef hat, Kai = laptop)

**Portrait composition:**
- Outline (1 px Deep Black)
- Background neutral lub kategoria color (low saturation)
- Face takes 60% of canvas, accessories visible
- Personality through posture, not facial detail (face is too small for detail)

### 4.4 UI elements

**Buttons:**
- Normal state: midtone color + 1px outline
- Pressed state: -1 px shadow offset (looks pushed in)
- Disabled: desaturated to gray ramp

**Text on UI:**
- **Pixel font tylko**: użyj "m5x7" (free) lub "PixelOperator" (free) — both are 7 px tall
- **Number display** (cash, IP): **Press Start 2P** lub custom — wider, more impactful
- Polish/diacritics support: m5x7 ma support, PixelOperator ma

**Floating numbers** (when sklep zarabia):
- 8x8 lub 16x16 quad
- "+$X" w zielonym (`#5BC15B`) z white outline
- Animation: float up 30 px over 1 sec, fade last 0.3 sec
- **Pool of 30 reusable** — nie spawn nowych instancji

### 4.5 Effects & Particles

**Coin particle:**
- 8x8 px, 4-frame spin animation (front → 3/4 → side → 3/4 → loop)
- Colors: gold ramp `#A8530F` → `#FFCB45` → `#FFE872`

**Star particle:**
- 8x8, single frame, fade out animation
- Colors: `#FFE872` core, `#FFCB45` outer glow

**VIRAL effect:**
- Screen-wide particle burst
- Magenta (`#8E3FB0`) and Hot Pink (`#FF004D`) confetti
- "VIRAL!" text 32x16 px, scales 0 → 1.2 → 1.0 over 0.5 sec
- Camera shake 0.3 sec

**Smoke/launch effect:**
- 16x16, 6-frame animation (smoke puff → expand → fade)
- Used when launching marketing campaign

### 4.6 Backgrounds (per prestige tier)

Background zmienia się **po prestige** — wizualny reward dla gracza.

| Prestige # | Background style | Mood |
|-----------|------------------|------|
| 0 (start) | Wieś, zielona trawa, domki w tle | Cozy, peaceful |
| 1 | Małe miasteczko, suburb, więcej budynków | Growing |
| 2-3 | Średnie miasto, parki, fontanna w centrum | Established |
| 4-6 | Metropolia, drapacze chmur, ruch | Dominant |
| 7-9 | Futurystyczne miasto, neon, hologramy | Futuristic |
| 10+ | Cyberpunk megacity, latające pojazdy | Endgame |

Każdy background ma: 3 layers (parallax) — odległe tło, średnie, foreground.

---

## 5. AI Generation Workflow

### 5.1 Pipeline overview

```
1. Concept (sketch lub opis)
       ↓
2. AI Generation (Stable Diffusion local lub Midjourney)
       ↓
3. Wybór 1 z 4-8 wariantów
       ↓
4. Aseprite cleanup (palette enforcement, AA removal)
       ↓
5. Export PNG with transparency
       ↓
6. Add to TexturePacker → atlas
       ↓
7. Reference w Godot scene
```

### 5.2 Stable Diffusion (lokalnie, free) — REKOMENDOWANE

**Setup:**
- Install [AUTOMATIC1111 WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) lub [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- Pobierz model: **PixelArtRedmond v3** (specjalnie do pixel art) — z Civitai
- Alternatywnie: **AlbedoBase XL** + LoRA "pixel-art-xl" (Civitai)

**Wymagania sprzętowe:**
- GPU 8GB VRAM minimum (RTX 3060 lub lepsza)
- Bez GPU: użyj Replicate.com / RunPod (ok 0.50 USD za sesję 1h)

### 5.3 Master Prompt Template

```
pixel art, 16-bit retro style, [SUBJECT], [SIZE] sprite, 
clean black 1px outline, limited palette, [VIEW] view, 
transparent background, Stardew Valley aesthetic,
no anti-aliasing, sharp pixels, retro game asset,
[CATEGORY-SPECIFIC DETAILS]
```

**Negative prompt (zawsze):**
```
blurry, anti-aliased, smooth shading, 3d, realistic, 
modern, photorealistic, gradient, glow, soft shadows,
high resolution, watermark, text, signature
```

### 5.4 Konkretne prompty per kategoria

#### Sklep — Fashion Boutique Lvl 1 (32x32)

```
pixel art, 16-bit retro style, small fashion boutique storefront,
32x32 sprite, clean black 1px outline, pink and red color palette
(#D8334A primary, #FF7A8A accent), front view, single story building,
mannequin in window, "FASHION" sign, transparent background,
Stardew Valley aesthetic, no anti-aliasing, sharp pixels
```

**Negative:** standard + `realistic clothes, photo, modern minimalist`

#### Sklep — Tech Store Lvl 2 (48x48)

```
pixel art, 16-bit retro style, two-story electronics shop,
48x48 sprite, clean black 1px outline, blue and cyan color palette
(#2E7BD1 primary, #00E0F0 neon accent), front view,
glowing TV screens in window, satellite dish on roof, 
"TECH STORE" neon sign, futuristic but retro feel,
transparent background, no anti-aliasing
```

#### Klient — Casual shopper (16x24)

```
pixel art, 16-bit retro style, casual shopper character,
16x24 sprite, full body side view, clean black 1px outline,
plain t-shirt and jeans, holding shopping bag,
neutral colors, walking pose, transparent background,
Stardew Valley NPC style, no anti-aliasing
```

#### Manager portrait — Sara Couture (64x64)

```
pixel art, 16-bit retro style, portrait of Parisian fashion designer,
64x64 sprite, clean black 1px outline, woman with black bob haircut,
black beret, red lipstick, sophisticated expression,
neutral cream background (#FFF1E8), shoulders visible,
limited palette, Stardew Valley character portrait style,
no anti-aliasing, sharp pixels
```

#### Coin particle (8x8)

```
pixel art, 8x8 sprite, single gold coin front view,
clean black 1px outline, gold gradient (#FFCB45 to #FFE872),
dollar sign on front, transparent background,
no anti-aliasing, retro game currency icon
```

#### Tile — Grass (16x16)

```
pixel art, 16x16 seamless tile, green grass texture,
top-down view, slight variation in green tones
(#1E5A3A shadow, #3CA858 mid, #8FE38A highlight),
no outline, tileable, Stardew Valley grass tile style,
no anti-aliasing
```

#### Effect — VIRAL particle (16x16)

```
pixel art, 16x16 sprite, magenta star burst particle,
hot pink and purple confetti (#FF004D, #8E3FB0),
white core, radial pattern, transparent background,
no anti-aliasing, retro celebration effect
```

#### UI — Money/Cash icon (16x16)

```
pixel art, 16x16 icon, dollar bill rolled up,
clean black 1px outline, green color palette
(#1E5A3A, #3CA858, #5BC15B, #8FE38A),
white and gold accents, transparent background,
no anti-aliasing, retro game UI element
```

#### App Icon (master 128x128)

```
pixel art, 128x128 sprite, retro pixel art icon for mobile game,
gnome shopkeeper character holding gold coin,
"$" symbol prominent, vibrant pixel art style,
limited palette (gold, red, blue, white),
clean composition, eye-catching, app store ready,
Stardew Valley meets AdVenture Capitalist aesthetic,
no anti-aliasing, professional pixel art
```

### 5.5 Aseprite Cleanup Workflow (KRYTYCZNE!)

Po wygenerowaniu AI sprite-a **NIGDY nie wrzucaj go do gry bez Aseprite cleanup**. AI dodaje:
- Anti-aliasing (subtelne pośrednie kolory na krawędziach)
- Kolory spoza palety
- Inconsistent pixel size
- Random noise pixels

**Cleanup steps (10-15 min per sprite):**

1. Otwórz sprite w Aseprite
2. **Load palette**: `Edit → Preferences → Palette → Load preset → capitalo_master_palette.gpl`
3. **Resize jeśli trzeba**: `Sprite → Sprite Size → exact pixel size` (e.g. 32x32) z `Algorithm: Nearest Neighbor`
4. **Force palette**: `Sprite → Color Mode → Indexed → palette: Capitalo Master`
5. Manualne fixy:
   - Użyj **Pencil tool** (nie Brush) — Brush ma anti-aliasing
   - Sprawdź outline (powinien być 1 px Deep Black)
   - Usuń floating pixels
   - Wyczyść tło (Magic Wand z 0% tolerance + Delete)
6. **Export**: `File → Export → PNG`, **8-bit indexed**, transparent background

### 5.6 Quality control — kiedy odrzucić sprite

**Hard rejects:**
- ❌ Zawiera kolory spoza Master Palette
- ❌ Ma wyraźny anti-aliasing (gradients na krawędziach)
- ❌ Outline jest niespójny (raz czarny, raz brązowy)
- ❌ Niespójna skala pixeli (niektóre części wyższa rozdzielczość)
- ❌ Niereadable w 100% scale na telefonie
- ❌ Nie pasuje do reszty assetów wizualnie

**Soft rejects (do iteracji):**
- ⚠️ Charakter/sklep niezgodny z brand color z shops.json
- ⚠️ Brakuje "iconic accessory" dla managera
- ⚠️ Animation frames niepłynne

---

## 6. Asset Production Roadmap

### 6.1 Phase 1 (MVP) — minimum viable assets

**Total: ~80 unique sprites, ~30-40h pracy**

#### Tilesets miasta (8 sprite'ów)
- Grass (3 variants)
- Sidewalk (3 variants)
- Street (4 directions + 4 intersections combined)
- Trees, bushes, lamps (3 sprite'y)

#### Budynki Phase 1 — 3 kategorie x 3 levele = 9
- Fashion Lvl 1, 2, 3
- Tech Lvl 1, 2, 3
- Food Lvl 1, 2, 3

#### Klienci (5 sprite'ów + animations)
- Casual, Premium, Kid, Senior, Influencer
- Each: 4-frame walk cycle = 20 frames total

#### Player avatar
- Gnome przedsiębiorca: idle (1) + walk (4 frames) = 5 frames

#### Manager portraits Phase 1 (9)
- 3 per kategoria (Fashion, Tech, Food) = 9 portraits + 9 walking sprites

#### UI elementy (~20)
- Buttons (3 states x 4 sizes = 12)
- Currency icons (coin, IP, star, etc. — 8)

#### Effects (~10)
- Coin spin (4 frames)
- Star particle (1)
- Smoke/launch (6 frames)
- VIRAL effect (8 frames)

#### Backgrounds
- Wieś (1 layered background, 3 layers)

### 6.2 Phase 2 (po MVP) — expansion

**Additional ~120 sprites, ~50-60h**

- 7 dodatkowych kategorii sklepów (Home, Beauty, Books, Toys, Sports, Luxury, Marketplace) x 3 levele = 21 budynków
- 9 dodatkowych managerów = 18 sprite'ów (portrait + walk)
- 5 backgrounds (po prestige tiers)
- Special event decorations (Black Friday, Christmas, Halloween, Valentine's)
- Additional effects (PR Crisis warnings, special viral types)
- Tech tree node icons (~50 unique 16x16 ikon)

### 6.3 Phase 3 (long tail)

- Skiny, alternative themes (Golden, Neon, Pastel)
- Seasonal decorations
- Animated billboards w sklepach
- Special manager animations (Singularity manager z innovation tree)

---

## 7. Pre-Production Checklist (per asset)

Każdy asset MUSI przejść tę checklistę przed dodaniem do gry:

### Każdy sprite:
- [ ] Używa **wyłącznie** kolorów z Master Palette
- [ ] Ma 1 px outline (Deep Black `#0F0F1B` lub Warm Gray `#5F574F`)
- [ ] **Brak anti-aliasingu** — każdy pixel jest "twardy"
- [ ] Spójna skala pixeli w całym sprite
- [ ] Dokładny rozmiar zgodny z sekcją 3.1
- [ ] Tło transparentne (PNG-8 indexed)
- [ ] Nazwa pliku zgodna z konwencją (sekcja 8)
- [ ] Działa wizualnie obok już istniejących assetów
- [ ] Czytelny w 100% scale na telefonie

### Sklepy specifically:
- [ ] Używa odpowiedniego brand color z shops.json
- [ ] Lvl 1 → Lvl 2 → Lvl 3 ma czytelną visual progression
- [ ] Sign / branding rozpoznawalne

### Postacie specifically:
- [ ] Iconic accessory obecny (manager Sara = beret, etc.)
- [ ] Animation frames płynne (test loop)
- [ ] Skin tone z palety (nie nowy kolor)

### UI specifically:
- [ ] Czytelna ikona w 16x16 / 32x32
- [ ] Pixel font użyty (nie smooth font)
- [ ] States (normal/pressed/disabled) spójne

---

## 8. File Naming Convention

```
[CATEGORY]_[SPECIFIC]_[VARIANT]_[FRAME].png
```

Przykłady:
- `shop_fashion_lvl1.png` — sklep, Fashion, Level 1
- `shop_fashion_lvl1_night.png` — wariant nocny
- `customer_casual_walk_01.png` — klient, casual, walk frame 1
- `customer_casual_walk_02.png` — frame 2
- `manager_sara_portrait.png` — portret Sary
- `manager_sara_walk_01.png` — Sara walk frame 1
- `ui_button_buy_normal.png` — UI, button "buy", normal state
- `ui_button_buy_pressed.png` — state pressed
- `effect_viral_burst_01.png` — efekt viral burst frame 1
- `tile_grass_01.png` — tile trawy variant 1
- `icon_coin_01.png` — ikona coin frame 1
- `bg_village_layer1.png` — background wieś warstwa 1

**Zasady:**
- Małe litery, snake_case
- Frames numerowane od 01 (z zerem!)
- Variants jako sufix
- Brak spacji, polskich znaków, kropek innych niż przed `.png`

---

## 9. Asset Folder Structure

```
assets/
├── sprites/
│   ├── shops/
│   │   ├── fashion/
│   │   │   ├── shop_fashion_lvl1.png
│   │   │   ├── shop_fashion_lvl2.png
│   │   │   └── shop_fashion_lvl3.png
│   │   ├── tech/
│   │   ├── food/
│   │   └── ... (+7 more for Phase 2)
│   ├── customers/
│   │   ├── casual/
│   │   │   ├── customer_casual_idle.png
│   │   │   ├── customer_casual_walk_01.png
│   │   │   ├── customer_casual_walk_02.png
│   │   │   ├── customer_casual_walk_03.png
│   │   │   └── customer_casual_walk_04.png
│   │   ├── premium/
│   │   ├── kid/
│   │   ├── senior/
│   │   └── influencer/
│   ├── managers/
│   │   ├── portraits/
│   │   │   ├── manager_alex_portrait.png
│   │   │   ├── manager_sara_portrait.png
│   │   │   └── ...
│   │   └── walks/
│   │       ├── manager_alex_walk_01.png
│   │       ├── manager_alex_walk_02.png
│   │       └── ...
│   ├── player/
│   │   ├── player_idle.png
│   │   └── player_walk_01..04.png
│   ├── ui/
│   │   ├── buttons/
│   │   ├── icons/
│   │   ├── panels/
│   │   └── frames/
│   ├── effects/
│   │   ├── coin_spin/
│   │   ├── viral_burst/
│   │   ├── star_particle/
│   │   └── smoke/
│   ├── tiles/
│   │   ├── grass/
│   │   ├── sidewalk/
│   │   └── street/
│   └── backgrounds/
│       ├── village/
│       ├── town/
│       ├── city/
│       └── metropolis/
├── audio/
│   ├── music/
│   └── sfx/
├── fonts/
│   ├── m5x7.ttf
│   ├── PixelOperator.ttf
│   └── PressStart2P.ttf
└── palettes/
    ├── capitalo_master_palette.gpl   (do Aseprite)
    ├── capitalo_master_palette.json  (do gry, tooling)
    └── capitalo_master_palette.svg   (visual reference)
```

---

## 10. Tooling Setup

### 10.1 Required Tools

| Tool | Purpose | Cost | Link |
|------|---------|------|------|
| **Aseprite** | Pixel art editor (CRITICAL) | $20 jednorazowo | https://aseprite.org |
| **TexturePacker** | Sprite atlas generation | Free version OK | https://www.codeandweb.com/texturepacker |
| **AUTOMATIC1111 WebUI** | Stable Diffusion local | Free | https://github.com/AUTOMATIC1111/stable-diffusion-webui |
| **Pixaki** (iOS/iPad) | Mobile pixel art editing | $30 jednorazowo | App Store |

### 10.2 Aseprite Setup

1. **Import master palette**: `File → Open → capitalo_master_palette.gpl`
2. **Save as preset**: `Palette → Presets → Save current...` → "Capitalo Master"
3. **Default settings**:
   - Pixel-perfect tools: ON
   - Snap to pixel: ON  
   - Anti-aliasing: ALWAYS OFF
   - Color mode: Indexed (po cleanup)
4. **Hotkeys** (recommended):
   - B: Pencil
   - E: Eraser
   - G: Paint Bucket (0% tolerance)
   - I: Eyedropper
   - Tab: Toggle palette panel

### 10.3 TexturePacker Settings

- **Algorithm**: MaxRects (best packing)
- **Format**: Godot (Atlas + JSON)
- **Trim mode**: Trim
- **Allow rotation**: NO (Godot prefers no rotation)
- **Pixel format**: RGBA8888
- **Anti-alias**: NO

---

## 11. Audio Style (krótka wstawka)

Wizualnie game = pixel art retro. Audio = **chiptune + minimal SFX**.

### Music
- 1 menu theme (chill, looping, ~1 min)
- 1 gameplay theme (upbeat, looping, ~2 min)
- 1 viral hit stinger (2 sec)
- 1 prestige theme (epic, 30 sec)

**Source:**
- **Free**: OpenGameArt.org (CC0 chiptune music)
- **AI Generated**: Suno AI ($10/mies subscription, very good quality)
- **Custom**: Hire indie composer ($50-200 per track on Fiverr/Reddit)

### SFX (min. 15)
- Click button, coin collect, cash register, whoosh launch, VIRAL stinger,
  FAIL trombone, manager hired jingle, level up, new shop unlocked fanfara,
  PR crisis alarm, achievement unlock, viral mega event, prestige reset,
  campaign success, campaign fail

**Source:**
- **Free**: Freesound.org, Pixabay sounds (filter: CC0)
- **Generated**: [sfxr](https://sfxr.me/) lub [jsfxr](https://sfxr.me/) — browser tool, generuje 8-bit SFX in seconds

---

## 12. Common Pitfalls (czerwone flagi)

### Z mojego doświadczenia analizą setek pixel art games:

1. **"Mam 5 różnych palet bo każdy sklep dostał inną"** → KATASTROFA, gra wygląda chaotycznie. Master Palette enforcement to pryncypium #1.

2. **"AI generated wygląda super, wrzuciłem bez cleanup"** → Po 2 godzinach grania widać "AI feel" — niespójne kolory, smudge edges. Cleanup = nieuniknione.

3. **"Sklepy lvl 2 i lvl 3 to to samo, tylko bigger"** → Gracze poczują brak progresji. Każdy level musi mieć **iconic addition** (neon, drone, signage).

4. **"Outline jest tylko gdzieniegdzie"** → Niespójne sprite. Albo wszystkie mają outline, albo żaden.

5. **"Przesadziłem z paletą bo chciałem jeszcze 5 dodatkowych odcieni"** → Im mniej kolorów, tym **silniejszy** styl. Limit jest feature.

6. **"Zostawiłem AI prompt 'photorealistic'"** → Klassyczny błąd. Prompt MUST kategorycznie wykluczać realism, AA, gradients.

7. **"Manager Sara wygląda jak Manager Lisa"** → Brak iconic accessory. Każdy manager musi być rozpoznawalny w 0.5s.

8. **"Tła zmieniają się losowo per scene"** → Background powinien zmieniać się tylko po prestige. Spójność > variety.

9. **"Liczyłem że AI da mi animacje"** → AI generuje single frames. Animacje robisz w Aseprite klatka po klatce. Zaplanuj czas.

10. **"Wszystkie 80 sprite'ów na raz przed kodem"** → Lepiej: 10 placeholderów + kod + iteracja. Po co skończony asset jeśli mechanika zmieni potrzebę?

---

## 13. Iteration & Versioning

### 13.1 Asset versioning

W Aseprite: zachowuj `.aseprite` source files w katalogu `assets/sources/`. Eksportowane PNG idą do `assets/sprites/`.

Naming source: `shop_fashion_lvl1_v3.aseprite` (z numerem wersji).

### 13.2 Asset review schedule

- **Co 2 tygodnie** podczas Phase 1: sprawdź wszystkie assety obok siebie w "asset sheet" (jeden duży PNG z wszystkim)
- Identify visual outliers
- Refactor jeśli coś wybija się ze stylu

### 13.3 Player feedback integration

- Po soft launch: zbieraj reviews wspominające visual ("ugly", "cute", "unclear")
- Iteracja na najbardziej widocznych assetach (sklepy, klienci)
- **NIE iteruj na UI** — zmiana UI w live game może zdezorientować graczy

---

## 14. Final Notes

Ten style guide to **żywy dokument**. Aktualizuj go gdy:
- Dodajesz nową kategorię assetów (np. seasonal decorations)
- Zmieniasz paletę (rzadko! Tylko jeśli fundamentalny problem)
- Odkrywasz nowy AI prompt template który działa świetnie
- Player feedback pokazuje konkretny visual issue

**Każda zmiana w tym dokumencie = aktualizacja przed produkcją nowych assetów.**

Pixel art jest disciplined craft. Constraints tworzą charakter. Ten guide to fundament — trzymaj się go i Capitalo będzie wyglądało jak **profesjonalna produkcja**, nie hobby project.

---

**END OF STYLE GUIDE v1.0**
