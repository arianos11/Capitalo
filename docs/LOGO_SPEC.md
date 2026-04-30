# Capitalo — Logo & Branding Spec v1.0

> Logo to pierwsza rzecz którą widzi gracz w app store. Ma 0.5 sekundy żeby przekonać do tapnięcia "Install".

---

## 1. Co logo musi komunikować

**W kolejności priorytetów:**

1. **TO JEST GRA** (nie aplikacja finansowa) — dlatego pixel art, kolorowo, z postacią
2. **TYCOON / BUSINESS** (potencjalny gracz musi wiedzieć o czym to) — dlatego coiny, dolar
3. **RETRO/PIXEL** (target audience: 25-40, nostalgia) — disciplined pixel art
4. **CHARAKTER** (branding ma być zapamiętywalny) — gnome-przedsiębiorca jako mascot
5. **PROFESJONALIZM** (musi wyglądać jak studio, nie hobby) — czysta kompozycja, nie chaos

## 2. Decyzja: gnome-przedsiębiorca jako mascot

**Dlaczego gnome przedsiębiorca:**
- ✅ **Memetyczny** — gnomy w gamingu (Warcraft, Plants vs Zombies) są lubiane
- ✅ **Genre-bridging** — łączy "fantasy retro" (pixel art audience) z "biznesem" (tycoon audience)
- ✅ **Charakter** — w przeciwieństwie do generic "businessman silhouette", gnome ma osobowość
- ✅ **Skalowalność brandu** — może być w cutscenes, jako manager, na merchandise
- ✅ **Polski twist** — krasnale w polskiej kulturze (Wrocławskie krasnale, Disney)

**Co gnome NIE robi:**
- ❌ Nie trzyma topora ani magicznego artefaktu (to nie fantasy)
- ❌ Nie jest stary i zmęczony (nie "wise wizard")
- ❌ Nie jest przesadnie cute (nie target dla dzieci)

**Co gnome ROBI:**
- ✅ Trzyma worek z pieniędzmi LUB stos coinów
- ✅ Stoi pewnie, lekko uśmiechnięty (pewny siebie biznesmen)
- ✅ Ma elementy "business" — krawat, monocle, kapelusz top hat (subtelne, nie cosplay)
- ✅ Czerwona/granatowa shirt + brązowe spodnie (palette colors)

## 3. Wymiary

### 3.1 Wszystkie wymagane outputy

| Asset | Rozmiar | Use case |
|-------|---------|----------|
| **Master logo** | 128x128 | Wszystkie pochodne |
| **App icon (iOS)** | 1024x1024 | App Store submission (skalowane z mastera nearest-neighbor) |
| **App icon (Android)** | 512x512 | Google Play submission |
| **Adaptive icon (Android)** | 432x432 (foreground) | New Android icon system |
| **In-game splash** | 256x256 | Loading screen |
| **In-game header logo** | 256x64 | Pasek menu (logo + tekst "CAPITALO") |
| **Favicon** (jeśli web landing) | 32x32 | Browser tab |
| **Social media avatar** | 400x400 | Twitter/Instagram/TikTok @capitalogame |
| **Social media banner** | 1500x500 | Twitter banner |

**WAŻNE:** Wszystkie pochodne pochodzą z **jednego masteru 128x128** poprzez **nearest-neighbor scaling** (NIGDY nie używaj bicubic/lanczos — to zniszczy pixel art).

### 3.2 Safe zones (App Store guidelines)

- **iOS:** rounded corners 22% radius. Logo musi mieć przynajmniej **8 px margin** od edge (w masterze 128x128 → safe zone 112x112 wewnątrz)
- **Android adaptive:** **system maskuje 1/3 ikony**. Główny element musi być w środkowych **66%** (canvas 432x432, safe zone 288x288 w środku)

## 4. Kompozycja

### 4.1 Layout master 128x128

```
┌─────────────────────────────┐
│  [bg: solid color or simple │
│   gradient w paleta]        │
│                             │
│        ▼                    │
│      [GNOME]                │
│      [holding coin]         │
│        ▼                    │
│                             │
│  [bottom 20% safe area]     │
└─────────────────────────────┘
```

**Pozycjonowanie:**
- Gnome zajmuje **70% wysokości** (od y=12 do y=102)
- Centered horizontally (x=32 do x=96, ~64 px wide)
- Coin/money element **nad lub obok** gnoma (eye-catching)
- Tło: **solid color** lub very simple geometric shape (nie complex pattern — w 32x32 zniknie)

### 4.2 Tło logo

**Opcja A (REKOMENDOWANE): Granatowe + złoty akcent**
- Background: `#1D2B53` (Dark Navy z palety) lub `#1A4A8C` (Deep Blue)
- Subtle radial highlight w jednym rogu w `#FFCB45` (Gold Yellow) → premium feel
- Gnome stoi przed tym tłem
- **Dlaczego**: granat + złoto = klasyczny "premium business" w app store

**Opcja B: Cream + character focus**
- Background: `#FFF1E8` (Cream White)
- Gnome wyrazisty z czarnym outline
- Ramka `#0F0F1B` (Deep Black) wokół całości
- **Dlaczego**: czysto, retro arcade feel, wyróżnia się od ciemnych konkurentów

**Opcja C: Splitscreen**
- Top half: Sky Blue (`#2E7BD1`)
- Bottom half: Bright Green (`#3CA858`) — trawa
- Gnome na granicy
- **Dlaczego**: sygnalizuje "outdoor world building" (city tycoon)

**Mój pick:** **Opcja A** — granat + złoto najlepiej działa w app store thumbnail (kontrastuje z białym BG sklepu).

### 4.3 Elementy sygnalizujące "money/tycoon"

**Hierarchia ważności (must-have → nice-to-have):**

1. **MUST**: Złoty coin trzymany przez gnoma LUB stos coinów u jego stóp
2. **MUST**: Dolar sign `$` widoczny gdzieś (na coinie lub na worku z pieniędzmi)
3. **SHOULD**: Sparkle/highlight efekt na coinie (8x8 pixel star)
4. **NICE**: Krawat lub bowtie na gnomie
5. **NICE**: Top hat lub bowler hat

**NIE** wrzucaj wszystkiego na raz. **Złota zasada**: 2-3 elementy wizualne max. W 128x128 więcej znaczy chaos.

### 4.4 Tekst "CAPITALO"

**W app icon:** ❌ NIE umieszczaj tekstu w app icon. Pixel font w 128x128 będzie nieczytelny po skalowaniu do 60x60 (tile w iPhone homescreen). App icon = pure visual identity.

**W in-game header logo (256x64):** ✅ Dodaj tekst "CAPITALO" obok ikony gnoma.
- Font: **Press Start 2P** (free, Google Fonts) — klasyczny retro arcade vibe
- Lub: **m5x7** (free, itch.io) — bardziej miękki pixel font
- Color: `#FFCB45` (Gold) z `#0F0F1B` (Deep Black) outline
- Rozmiar tekstu: ~32 px height
- Litery dobrze odczytywane: **C-A-P-I-T-A-L-O** (8 znaków, idealnie balansuje się)

## 5. AI Generation Prompts

### 5.1 Master Logo Prompt (128x128)

**Dla Stable Diffusion (PixelArtRedmond / SDXL + pixel-art LoRA):**

```
pixel art, 16-bit retro style, app icon for mobile tycoon game,
cute gnome businessman character, holding glowing gold coin,
red shirt with bowtie, brown beard, top hat, confident pose,
dark navy background (#1D2B53), gold radial highlight,
clean black 1px outline, limited palette,
128x128 sprite, sharp pixels, no anti-aliasing,
Stardew Valley meets AdVenture Capitalist aesthetic,
professional pixel art, app store ready,
centered composition, transparent edges
```

**Negative prompt:**
```
blurry, anti-aliased, smooth shading, 3d, realistic, modern,
photorealistic, gradient, glow blur, soft shadows, multiple characters,
text, letters, watermark, signature, low quality, jpeg artifacts,
photographic, complex background, busy composition
```

**Settings:**
- Sampler: DPM++ 2M Karras (or Euler a)
- Steps: 30-40
- CFG Scale: 7-9
- Seed: random first, then lock when you find good base
- Resolution: **start 512x512**, downsample to 128x128 in Aseprite (more detail to clean up)

### 5.2 Wariant A — Pewny siebie biznesmen-gnome

```
pixel art, 16-bit retro mobile game app icon,
gnome character businessman, hands on hips confident pose,
red shirt and gold bowtie, brown pointed wizard hat,
gold coins floating around him, dollar sign on largest coin,
dark navy background with gold spotlight,
sharp pixel art, clean black outline,
limited palette, no anti-aliasing, 128x128 sprite,
professional retro game icon
```

### 5.3 Wariant B — Gnome z worem pieniędzy

```
pixel art, 16-bit retro mobile game app icon,
short gnome character holding huge gold money sack,
"$" symbol on the sack, smile expression, brown beard,
classic red wizard cap, dark navy background,
gold sparkle effect on money sack,
sharp pixel art, clean black 1px outline,
limited palette, no anti-aliasing, 128x128 sprite
```

### 5.4 Wariant C — Empire builder

```
pixel art, 16-bit retro mobile game app icon,
gnome shopkeeper character standing proudly,
small pixel art shop building behind him,
holding single large gold coin up to the sky,
red shirt, brown overalls, friendly smile,
sky blue and green split background,
sharp pixel art, clean black outline, limited palette,
128x128 sprite, no anti-aliasing
```

### 5.5 Po generation — Aseprite cleanup

**6 kroków po wybraniu najlepszego AI output:**

1. **Open w Aseprite** (file 512x512 z SD)
2. **Sprite → Sprite Size → 128x128**, Algorithm: **Nearest Neighbor** (KRYTYCZNE!)
3. **Load palette**: capitalo_master_palette.gpl
4. **Sprite → Color Mode → Indexed** (force palette)
5. **Manual fixes** (15-30 min):
   - Wyczyść outline (1 px Deep Black wszędzie)
   - Usuń floating pixels (2-3 magic wand cleanups)
   - Dodaj missing details (czasem AI pomija krawędzie)
   - Sprawdź czy oczy gnoma są symetryczne
6. **Export PNG** 128x128, indexed, transparent (jeśli używasz Opcję B/C tła) lub solid bg (Opcja A)

## 6. App Store Optimization (ASO) — co poza logiem

### 6.1 Screenshots (App Store wymaga 5-10)

Przygotuj **6 screenshotów** dla soft launch:

1. **Hero shot** — miasteczko z 5 sklepami, animowane klienty, "BUILD YOUR EMPIRE" overlay
2. **Marketing campaign action** — viral hit moment z "VIRAL!" wyświetlonym
3. **Tech tree** — pokazuje deep meta-progression
4. **Multiple shops** — 3-4 kategorie odblokowane
5. **Manager portrait modal** — pokazuje "characters with personality"
6. **Prestige moment** — "PRESTIGE EARNED" z liczbą IP

**Format**: 1290x2796 px (iPhone 15 Pro Max) lub 1284x2778 (iPhone 14 Pro Max).

### 6.2 App Store metadata

**Title:** `Capitalo`  
**Subtitle (iOS) / Short description (Android):** `Idle Pixel Tycoon Empire`  
**Long description starter (do iteracji):**

```
Build your retail empire from a single fashion boutique to a global marketplace 
in this charming idle tycoon game with pixel art aesthetic.

✨ MARKETING-DRIVEN GAMEPLAY
Click to launch ad campaigns. Roll for viral hits. Build your brand.

🏪 10 SHOP CATEGORIES  
Fashion, Tech, Food, Beauty, Toys, Sports, Luxury... and more.

📈 DEEP TECH TREE
4 branches, 48 nodes. Drones, AI managers, quantum sales.

⏸️ FAIR MONETIZATION
No pay-to-win. No energy timers. Just one optional Premium Pack.

🎨 RETRO PIXEL ART
16-bit aesthetic inspired by classic tycoon games.

⚙️ STRATEGIC DEPTH
AI competitors. Seasonal events. PR crisis decisions. 
Everything matters.

Become the next retail mogul in Capitalo.
```

**Keywords (iOS, 100 chars):** `idle,tycoon,pixel,retro,clicker,business,empire,shop,management,merchant`

**Category:** Games → Simulation (primary), Games → Strategy (secondary)

**Age rating:** 4+ (no objectionable content)

## 7. Social Media Setup

### 7.1 Account checklist

Stwórz w **tej kolejności** (przed launch):

- [ ] **Twitter/X**: @capitalogame — najszybszy growth, gaming community tam żyje
- [ ] **TikTok**: @capitalogame — "dev journey" content (15-60s clipsy z Godot Editor)
- [ ] **Instagram**: @capitalogame — backup, screenshots
- [ ] **YouTube**: @capitalogame — devlog content, jeśli chcesz iść w tę stronę
- [ ] **Discord**: server "Capitalo Community" — fani, beta testerzy, feedback
- [ ] **Reddit**: zarejestruj user "u/capitalogame", subreddit później

### 7.2 Content strategy pre-launch (3-4 mies przed release)

**Twitter cadence:** 3-5 postów tygodniowo.

**Typy postów:**
- Screenshots WIP (Tuesday)
- Pixel art assets pojedyncze (Thursday) — community uwielbia "asset showcase"
- "Day X devlog" wątki (Friday) — bardzo lubiane na #gamedev
- Polls "Co budujemy następnie?" — engagement

**TikTok cadence:** 1-2 video tygodniowo.

**Format:**
- Screen recording z Godot — slowed-down zoom-ins
- Voiceover (twój głos) lub muzyka chiptune
- Hashtags: #pixelart #gamedev #indiedev #idlegame

**Why it matters:** Według statystyk indie launch z **0 social presence** ma typowo 50-100 wishlistów. Z aktywnym Twitter (3 mies, 100 followers) → 500-2000 wishlistów. To jest **decyduje** czy gra wystartuje na sklepach z trakcją.

## 8. Trademark Protection (po soft launch)

Po **soft launch i potwierdzeniu trakcji** ($500+ MRR lub 1000+ DAU):

1. **USPTO trademark search** (USA): https://tmsearch.uspto.gov
   - Wpisz "Capitalo"
   - Sprawdź klasy 9 (software), 41 (entertainment)
   - Cost: $250-350 per class
   
2. **EUIPO trademark** (UE): https://euipo.europa.eu
   - Trademark UE — jednolita ochrona w 27 krajach
   - Cost: €850-1050

3. **Polski Urząd Patentowy** (PL): jeśli chcesz polską ochronę
   - Cost: 400-700 zł

**Jeśli budżet napięty:** rób **TYLKO EUIPO**. Pokrywa Polskę + ważne rynki europejskie. USA możesz dodać później.

---

## 9. Final checklist przed wypuszczeniem logo

- [ ] Master 128x128 wygenerowane i cleaned w Aseprite
- [ ] Tylko kolory z Master Palette (sprawdź w Aseprite — Color Mode Indexed)
- [ ] 1 px Deep Black outline wszędzie
- [ ] Czytelne w 60x60 (test: zmniejsz do tej rozdzielczości i spójrz)
- [ ] Czytelne na białym tle (App Store) i czarnym (homescreen wallpaper test)
- [ ] iOS rounded corners 22% nie obcinają nic ważnego
- [ ] Android adaptive icon: główny element w środkowych 66%
- [ ] Eksport: PNG 1024x1024 (iOS) i 512x512 (Android) nearest-neighbor
- [ ] In-game header logo (256x64) z tekstem "CAPITALO"
- [ ] Favicon 32x32 (jeśli web landing)
- [ ] Social avatars 400x400

---

**END OF LOGO SPEC v1.0**
