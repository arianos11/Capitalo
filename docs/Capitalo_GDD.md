# Capitalo — Game Design Document v1.0

> Dokument projektowy idle/clicker tycoon na iOS i Android.
> **Autor:** Arian + Claude
> **Data:** kwiecień 2026
> **Cel dokumentu:** kompletna specyfikacja dla Claude Code do implementacji.

---

## 1. Executive Summary

**Capitalo** to mobilna idle/clicker tycoon w retro pixel art (16-bit), w której gracz buduje globalne imperium e-commerce zaczynając od jednego małego sklepu. Gra wyróżnia się **marketing-driven core loop** (klikanie odpala kampanie marketingowe z systemem szans i viralu), **żywą gospodarką** (AI konkurencji, eventy sezonowe, system reputacji) oraz **rozbudowanym tech tree** jako głównym systemem meta-progresji.

**Target audience:** 25-45 lat, fani idle games (AdVenture Capitalist, Idle Miner Tycoon, Cookie Clicker), nostalgicy pixel art, casual gracze z entuzjazmem do strategii biznesowych.

**Platformy:** iOS (App Store), Android (Google Play). Single device, lekki online (leaderboardy, social).

**Monetyzacja:** Rewarded ads + opcjonalny banner + jeden premium IAP (Remove Ads + Premium Pack). Brak gachy, brak pay-to-win.

**Estymowany czas do MVP:** 2-3 miesiące part-time.
**Estymowany czas do v1.0:** 5-7 miesięcy part-time.

---

## 2. Filozofia projektowa

### 2.1. Pryncypia
1. **Player respect first** — żadnego ciemnego patternu, żadnego pay-to-win, żadnej energii/cooldownów blokujących grę.
2. **Każdy klik = decyzja** — nie chcemy bezmyślnego klikania, każda akcja gracza ma weight strategiczny.
3. **Pixel art jako feature, nie ograniczenie** — spójna paleta, ograniczone klatki animacji, retro-modern UI.
4. **Liczby muszą "śpiewać"** — idle game stoi ekonomią, balans nadrzędny nad content.
5. **Release early, iterate fast** — MVP > perfect, real player feedback > teoretyczne planowanie.

### 2.2. Jak Capitalo wyróżnia się od konkurencji
| Cecha | AdVenture Capitalist | Idle Miner | Cookie Clicker | **Capitalo** |
|-------|----------------------|------------|----------------|------------------|
| Core loop | Tap to collect | Tap to speed up | Click cookie | **Click to launch marketing** |
| Strategia | Niska | Średnia | Niska | **Wysoka (kampanie, AI competitors)** |
| Wizualnie | Generic cartoon | Cartoon | Minimalistyczny | **Pixel art retro** |
| Tech tree | Brak | Limited | Buildings | **Rozbudowane drzewo z 4 gałęziami** |
| Reputacja/PR | Brak | Brak | Brak | **System recenzji i kryzysów** |

---

## 3. Roadmap — Fazy rozwoju

Gra **NIE jest budowana w całości od razu**. Implementacja w fazach:

### Faza 1 — MVP (cel: 2-3 miesiące)
**Goal:** Grywalna gra na sklepie, podstawowa pętla.
- 3 kategorie sklepów (Fashion, Tech, Food)
- 4 typy kampanii marketingowych (Flyers, Facebook Ads, Google Ads, Influencer)
- Podstawowy system managerów (1 manager per sklep, 5 leveli)
- Prosty tech tree (10 nodów, 1 gałąź — Marketing)
- Prestige system z Innovation Points
- Offline earnings (max 8h)
- Save/Load (lokalny, JSON)
- Podstawowe SFX i muzyka tła
- Pixel art assety (vide sekcja 11)
- **Brak online, brak ads, brak IAP** — testujemy tylko gameplay loop

### Faza 2 — Soft Launch (cel: +1-2 miesiące)
- Wszystkie 10 kategorii sklepów
- Kompletny tech tree (4 gałęzie, ~50 nodów)
- AI Competitors (3-5 NPC firm)
- Eventy sezonowe (Black Friday, Christmas, etc.)
- Daily rewards + 7-day login streak
- Achievements system (~50 achievementów)
- Tutorial system (interaktywny first-time experience)
- AdMob integration (rewarded ads + opcjonalny banner)
- Analytics (Firebase/Unity Analytics)
- **Soft launch w Polsce + Czechy + Rumunia** (małe rynki = tani test)

### Faza 3 — Global Launch (cel: +1 miesiąc)
- System reputacji + PR Crisis events
- Premium IAP (Remove Ads + Premium Pack)
- Push notifications (1-2 dziennie max)
- Comeback bonus po 3+ dniach
- Localization (EN, PL, DE, ES, PT-BR, RU)
- Optymalizacja performance
- **Global launch — App Store + Google Play**

### Faza 4 — Live Ops (ongoing)
- Cloud save (Firebase) + leaderboardy + podgląd miast znajomych
- Battle pass / Sezony (3-miesięczne)
- Nowe kategorie/eventy/managerowie regularnie
- Społeczność (Discord, social media)

---

## 4. Stack techniczny

### 4.1. Engine: **Godot 4.x**
**Dlaczego Godot:**
- Darmowy, open-source, brak royalty
- Lekki (~100MB), szybki development
- GDScript jest prosty (Python-like) — Claude Code dobrze go pisze
- Dobry export do iOS i Android
- Built-in scene system idealny do takich gier
- Brak licencjnych pułapek (vs Unity 2023 fiasco)

### 4.2. Język: **GDScript** (główny) + ewentualnie **C#** dla wydajnościowo krytycznych części
GDScript wystarczy w 95% przypadków. C# tylko jeśli pojawią się bottlenecki przy obliczeniach ekonomii dużych liczb.

### 4.3. Persystencja danych
- **Faza 1-2:** lokalne pliki JSON w user://savegame.json
- **Faza 3+:** Firebase Firestore dla cloud save
- **BigNumber math:** custom klasa BigNumber.gd (idle games operują na liczbach 10^100+, float się nie nadaje)

### 4.4. Backend (Faza 3+)
- **Firebase** (Authentication anonymous + Firestore + Cloud Functions)
- Alternatywa: Supabase + edge functions
- Estymowany koszt: $0-50/mies. do 50k DAU

### 4.5. Ads & Analytics
- **AdMob** (Google) — najlepiej płaci globalnie
- **Firebase Analytics** — darmowe, integracja z AdMob
- Alternatywa: Unity LevelPlay (jeśli zmienimy engine)

### 4.6. Asset pipeline
- **Aseprite** — do edycji/poprawiania pixel art (jednorazowo $20)
- **AI generation:** Stable Diffusion (lokalnie, free) lub Midjourney/Ideogram do brainstormu, finalne assety w Aseprite
- **TexturePacker** — do tworzenia spritesheetów (free version wystarcza)
- **Audio:** freesound.org, Pixabay (CC0), opcjonalnie Suno AI dla muzyki tła

### 4.7. Repository
- **Git + GitHub** (private repo)
- Branche: `main` (release), `dev` (working), feature branches
- **GitHub Actions** dla automated builds (Android APK)

---

## 5. Core Gameplay Loop

### 5.1. Pętla podstawowa (sekunda po sekundzie)

```
1. Gracz patrzy na ekran z miasteczkiem (top-down view)
2. Widzi 1-10 sklepów, każdy generuje pasywny przychód
3. Klika "Launch Campaign" (przyciski kampanii w UI)
4. Roll szansy → wynik (success/viral/fail)
5. Sukces = boost klientów na X sekund → wzrost przychodu
6. Przychód → kupuje upgrade'y / nowe sklepy / tech tree nodes
7. Powtarza, eskaluje, prestige po ~40-60h
```

### 5.2. Marketing Campaign System (główna mechanika)

#### Typy kampanii (Faza 1: 4 typy, Faza 2: 7+)

| Kampania | Cooldown | Koszt | Base Success% | Viral% | Zasięg | Odblokowanie |
|----------|----------|-------|---------------|--------|--------|--------------|
| Flyers | 2s | $5 | 80% | 1% | 5-10 klientów | start |
| Facebook Ads | 5s | $50 | 70% | 5% | 30-80 klientów | $1k total revenue |
| Google Ads | 5s | $80 | 75% | 3% | 40-100 (targeted) | tech tree node |
| Influencer | 30s | $500 | 60% | 15% | 200-2000 klientów | $50k total revenue |
| TV Spot | 120s | $5000 | 90% | 8% | 1000-5000 | $1M total revenue |
| TikTok Viral | 60s | $200 | 40% | 25% | 50-50000 (gambling) | tech tree node |
| Super Bowl Ad | 3600s | $10M | 95% | 30% | 100k+ | endgame |

#### Mechanika rolla:
```python
def launch_campaign(campaign_type):
    # Modifiers from tech tree, managers, brand reputation
    success_chance = base_success + tech_modifier + brand_bonus
    viral_chance = base_viral + tech_viral_modifier
    
    roll = random(0, 100)
    
    if roll < viral_chance:
        # VIRAL HIT
        multiplier = 5 + (rare bonus from "Viral Studio" tech)
        duration = 120s
        play_special_animation()
        spawn_floating_text("VIRAL!")
        if mega_viral_chance triggers (1 in 100 of virals):
            multiplier = 10
            duration = 300s
            spawn_screenshot_moment()  # encourage social share
    elif roll < success_chance:
        # SUCCESS
        multiplier = 1.5
        duration = 30s
    else:
        # FAILURE
        # Money is still spent, small reputation hit
        spawn_floating_text("Flopped...")
```

#### Co robi success/viral mechanicznie:
- Spawnuje **klientów** (pixel sprite'y) chodzących po miasteczku do sklepów
- Klient w sklepie = +X $ do passive income przez Y sekund
- Viral = nagle 200+ klientów się pojawia, miasto żyje, dopaminowy moment
- **Floating numbers** lecą z każdego sklepu (znana mechanika z idle games)

### 5.3. Sklepy — mechanika

Każdy sklep ma:
- **Level** (1 → 1000+)
- **Base income** (skaluje wykładniczo z levelem)
- **Capacity** (max klientów obsłużonych /sek)
- **Manager** (slot na managera, automatyzuje sklep)
- **Upgrade'y** (specjalistyczne, per kategoria)
- **Reputation stars** (1-5, wpływa na chętność klientów)

#### Wzór na income (Faza 1):
```
sklep_income_per_sec = base_income(category) 
                      * (1.07 ^ level)         // exponential growth per level
                      * manager_multiplier      // manager bonus (1x do 5x)
                      * category_event_bonus    // event seasonality
                      * brand_reputation_bonus  // global multiplier
                      * prestige_multiplier     // meta progression
```

#### Koszt levelu (klasyczny idle):
```
level_cost(n) = base_cost * (1.15 ^ n)
```
1.15 to "magiczna stała" idle games (AdVenture Capitalist używa) — zapewnia że upgrade'y zawsze są "tuż poza zasięgiem" ale osiągalne.

### 5.4. Managerowie

System hybrydowy (Twój wybór):
- **Zakup permanentny** ($X za managera)
- **Levelowanie** (1-10, każdy level kosztuje innovation points lub kasę)

Manager robi:
- **Auto-sell** (sklep produkuje income bez kliknięć)
- **Speed boost** (+X% szybkości obsługi klientów)
- **Quality boost** (+X% reputation gain)
- **Special perk** per manager (np. "Sara: +50% income w weekendy")

15-20 managerów total (3 per kategoria + 5 globalnych).


---

## 6. Tech Tree — szczegółowa specyfikacja

### 6.1. Struktura ogólna

Tech tree to **główny system meta-progresji**, dostępny po pierwszym prestige. Innovation Points (IP) zarabia się tylko przez prestige.

```
                       ROOT
                        │
         ┌──────────┬───┴───┬──────────┐
         │          │       │          │
    MARKETING  OPERATIONS  HR    INNOVATION
    (Faza 1)   (Faza 2)  (Faza 2)  (Faza 3)
```

### 6.2. Gałąź MARKETING (Faza 1 — 10 nodów)

| Node | Koszt IP | Efekt | Wymaga |
|------|----------|-------|--------|
| Copywriting I | 1 | +10% success rate na Flyers/FB Ads | - |
| Copywriting II | 3 | +15% success rate na wszystkie | Copy I |
| Targeting Algorithm | 2 | Odblokowuje Google Ads | - |
| Viral Studio I | 5 | +5% viral chance globally | Copy I |
| Viral Studio II | 12 | +10% viral chance, +50% viral multiplier | Viral I |
| Marketing Automation | 8 | Auto-fire najtańszą kampanię co 5s | Copy II |
| Influencer Network | 10 | Odblokowuje Influencer campaign | Targeting |
| Brand Building I | 6 | +20% baseline customer flow | - |
| Brand Building II | 15 | +50% baseline + reputation gain | Brand I |
| TikTok Mastery | 20 | Odblokowuje TikTok Viral campaign | Viral II + Brand I |

### 6.3. Gałąź OPERATIONS (Faza 2 — 13 nodów)

Skupia się na sklepach/logistyce:
- Logistics I-III (szybsza dostawa = więcej sprzedaży)
- Inventory Management I-III (większa pojemność sklepów)
- Quality Control I-II (wyższa reputacja)
- Multi-store I-III (mniejsze koszty otwierania sklepów)
- Premium Locations (sklepy w prime spots dają +50% income)

### 6.4. Gałąź HR / AUTOMATION (Faza 2 — 12 nodów)

Skupia się na managerach:
- Training Program I-III (managers level cap +)
- HR Software (auto-hire najlepszych managerów)
- Robotics I-III (zastępuje manager slots = stack bonusów)
- AI Manager (endgame: AI manager z specjalnymi perks)
- Synergy Bonus (managerowie z tej samej kategorii dają stacking bonus)

### 6.5. Gałąź INNOVATION (Faza 3 — 15 nodów)

Endgame, prawdziwie potężne:
- Drone Delivery (eliminuje cooldowny dostawy)
- Quantum Sales (small chance for x100 sale)
- AI Analytics (auto-optymalizuje kampanie)
- Time Compression (offline earnings cap +50%)
- Empire Building (otwiera ekspansję geograficzną)
- Cross-promotion (sklepy boostują się nawzajem)
- Singularity (endgame node — dramatic boost ale wymaga wszystkich poprzednich)

### 6.6. Innovation Points — jak się zdobywa

Po każdym prestige (reset gry):
```
IP_zarobione = floor((total_money_earned / 1e9) ^ 0.5)
```

Pierwsze prestige: ~5-10 IP.
Po godzinach grania, gracz zdobywa 50-200 IP per prestige.
Cały tech tree wymaga ~500 IP — czyli ~10-20 prestiges do "ukończenia".

---

## 7. Żywa Gospodarka

### 7.1. AI Competitors (Faza 2)

System: **3-5 firm NPC** które rosną razem z graczem.

#### Persone konkurentów:

| Firma | Personality | AI behavior | Specjalność |
|-------|-------------|-------------|-------------|
| MegaCorp | Agresywny dyskonter | Często odpala promocje, wojny cenowe | Duża skala, low margin |
| Boutique & Co | Premium brand | Powolny wzrost, ale wysoka reputacja | Luxury, Beauty |
| FlashMart | Copy-cat | Robi to samo co gracz z 24h opóźnieniem | Jakakolwiek |
| TechGiants | Tech specialist | Dominuje Tech, słaby w innych | Tech only |
| StreetVendors | Underdog | Mały ale szybki, viral marketing | Food, Toys |

#### Mechanika market share:
- Globalny "rynek" = 100%
- Każda firma + gracz mają % market share
- Im więcej market share, tym więcej baseline klientów
- Akcje konkurencji wpływają na gracza:
  - "MegaCorp odpala 50% sale!" → -20% klientów na 2h, opcja "match price" lub "ride it out"
  - "Boutique & Co otwiera flagship store" → tracisz 5% market share w Beauty
- **Endgame:** Acquisition — możesz kupić konkurenta (cena = ich market_share * $1B)

### 7.2. Sezonowe Eventy

Gra **czyta real-time IRL**, eventy odpowiadają datom:

| Event | Daty | Boosty | Special |
|-------|------|--------|---------|
| Black Friday | 4. piątek listopada | x3 wszystkie kategorie 24h | Special leaderboard |
| Christmas | 20-26 grudnia | x2 Toys, Fashion, Food; x4 last day | Xmas decorations |
| Valentine's | 14 lutego | x3 Beauty, Luxury | Pink theme |
| Back to School | 25 sierpnia - 5 września | x2 Books, Tech | - |
| Summer Sale | 1-15 lipca | x2 Sports, Fashion | Beach theme |
| Easter | data zmienna | x2 Food, Toys | - |
| Halloween | 25-31 października | x2 Toys, Beauty | Spooky theme |

#### Daily events (nie real-time, in-game timer):
- "Trending Product Day" — random kategoria x2 przez 24h (in-game time)
- "Flash Sale" — wszystko x1.5 przez 30 min, raz na 6h

### 7.3. System Reputacji (Faza 3)

#### Jak się buduje:
- Sukces kampanii: +0.01 stars
- Failed campaign: -0.005 stars
- Quality manager: +0.02 stars/h
- Customer satisfaction (zależy od capacity sklepu vs flow): ±0.05 stars/h

#### PR Crisis Events:
Random event co 24-48h gameplay:
- "Klient znalazł włos w jedzeniu"
- "Influencer powiedział że Twoje produkty to cringe"
- "Pracownik wycieknął zdjęcia z back office"
- "Konkurencja oskarża Cię o copying"

Każdy crisis ma 3 opcje reakcji:
1. **Apology + refund** (kosztuje kasę, mała reputacja gain)
2. **Deny + lawyer** (kosztuje sporo, średnia reputacja, ryzyko backfire)
3. **Spin into marketing** (wymaga "PR Mastery" tech, duża reputacja gain jeśli sukces)

#### Viral Reviews (positive):
Random co 12-24h:
- "MrBeast filmował u Ciebie!" → +0.5 stars + customer surge
- "Twój produkt trafił na frontpage Reddita" → +0.3 stars
- Lokalna gazeta zrobiła positive feature


---

## 8. Ekonomia — liczby i krzywe

### 8.1. Filozofia ekonomii idle game

Idle games żyją krzywą wzrostu. Złe liczby = gra umiera w 30 minut. Reguły:
1. **Każdy "next purchase" musi czuć się osiągalny w 30s-2min**
2. **Ale nie za szybko** — inaczej gracz się znudzi
3. **Wykładniczy wzrost przychodu, wykładniczy wzrost cen, ale crescendo różnicy**
4. **Liczby muszą rosnąć dramatycznie** (od $5 do quintillionów) — to dopaminowy hit

### 8.2. Konkretne stałe (do ewentualnego strojenia w testach)

```gdscript
# Gospodarka core
const SHOP_LEVEL_COST_BASE = 10.0
const SHOP_LEVEL_COST_GROWTH = 1.15  # AdVenture Capitalist constant

const SHOP_INCOME_GROWTH = 1.07      # per level
const SHOP_BASE_INCOME_BY_CATEGORY = {
    "fashion": 1.0,
    "tech": 8.5,
    "food": 47.0,
    "home": 260.0,
    "beauty": 1400.0,
    "books": 7800.0,
    "toys": 44000.0,
    "sports": 250000.0,
    "luxury": 1.4e6,
    "marketplace": 8.0e6
}

# Każda kategoria ma ~5.6x większy base income od poprzedniej
# To zapewnia że nowa kategoria zawsze "wygrywa" gdy gracz ją odblokuje
# Ale stara też się opłaca rozwijać dla całościowej skali

# Kampanie marketingowe
const CAMPAIGN_COSTS = {
    "flyers": 5,
    "facebook": 50,
    "google": 80,
    "influencer": 500,
    "tv": 5000,
    "tiktok": 200,
    "superbowl": 10_000_000
}

# Cooldowns w sekundach
const CAMPAIGN_COOLDOWNS = {
    "flyers": 2.0,
    "facebook": 5.0,
    "google": 5.0,
    "influencer": 30.0,
    "tv": 120.0,
    "tiktok": 60.0,
    "superbowl": 3600.0
}

# Prestige
const PRESTIGE_FORMULA_BASE = 1e9        # earnings needed for first IP
const PRESTIGE_FORMULA_EXPONENT = 0.5    # sqrt curve
const PRESTIGE_MULTIPLIER_PER_IP = 0.02  # +2% income permanent per IP

# Offline earnings
const OFFLINE_CAP_HOURS = 8
const OFFLINE_EFFICIENCY = 0.5           # 50% of online rate
const OFFLINE_AD_BOOST_MULTIPLIER = 2.0  # watching ad = 2x offline

# Manager defaults
const MANAGER_BASE_MULTIPLIER = 2.0      # x2 income gdy manager hired
const MANAGER_LEVEL_BONUS = 0.1          # +10% per manager level (1-10)
```

### 8.3. Krzywa progresji (rough projection)

Przy normalnym graniu (kilka godzin dziennie):

| Czas | Total earned | Sklepy odblokowane | Tech tree progress |
|------|--------------|-------------------|---------------------|
| 5 min | $1k | 1 (Fashion) | brak (przed prestige) |
| 30 min | $50k | 2 (+ Tech) | brak |
| 2h | $1M | 3 (+ Food) | brak |
| 5h | $50M | 4 (+ Home) | brak |
| 10h | $1B | 5-6 | brak |
| 20h | $50B | 7-8 | brak |
| 40h | $1T | 9-10 | brak |
| 60h | First prestige | wszystkie | 5-10 IP zdobyte |

Po pierwszym prestige tempo przyspiesza dzięki bonusom.

### 8.4. BigNumber implementation (techniczne)

Idle games operują na liczbach 10^100+, JavaScript/GDScript float to 10^308 max ale traci precyzję powyżej 10^15.

**Rozwiązanie:** custom BigNumber jako struktura `{mantissa: float, exponent: int}`.

```gdscript
class_name BigNumber

var mantissa: float
var exponent: int  # 10^exponent

func _init(m: float = 0.0, e: int = 0):
    mantissa = m
    exponent = e
    normalize()

func normalize():
    if mantissa == 0:
        exponent = 0
        return
    while abs(mantissa) >= 10:
        mantissa /= 10
        exponent += 1
    while abs(mantissa) < 1 and mantissa != 0:
        mantissa *= 10
        exponent -= 1

func multiply(other: BigNumber) -> BigNumber:
    return BigNumber.new(mantissa * other.mantissa, exponent + other.exponent)

func add(other: BigNumber) -> BigNumber:
    # ...więcej logiki
    pass

func to_display() -> String:
    # "1.23K", "5.67M", "8.91B", "1.23 quintillion", etc.
    pass
```

Suffix list: K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc, Ud, Dd, Td, Qad, Qid, Sxd, Spd, Ocd, Nod, Vg... (do 10^60+ ma standardowe nazwy, potem AA, AB, AC).

---

## 9. Monetyzacja

### 9.1. Filozofia
**Etyczna monetyzacja**, długoterminowa retencja > szybkie pieniądze. Cel: gracz który nie płaci nadal ma 100% gameplay, gracz który płaci tylko "wspiera dewelopera" + dostaje wygodę.

### 9.2. Reklamy

#### Rewarded ads (główne źródło przychodu):
1. **Offline boost** — przy powrocie do gry: "Watch ad → 2x offline earnings"
2. **Booster x4** — przycisk "boost" w UI, 1 minuta x4 income, cooldown 30 min, każdy reset cooldownu = 1 ad
3. **Wheel of Fortune** — 1x na 4h, ad → spin koła nagród (kasa, IP, manager card, etc.)
4. **Skip cooldown** — kampania ma cooldown? Watch ad → resetuj
5. **Daily reward boost** — daily reward x2 jeśli oglądasz ad

#### Banner ads (opcjonalne):
- Bottom of screen, podczas gameplay
- **Toggle w settings** — gracz może wyłączyć
- Nie wyświetla się w czasie viral hits (żeby nie zepsuć momentu)

### 9.3. Premium IAP

**JEDEN produkt:** "Premium Pack" za **$4.99** (~20 zł):
- Permanentnie wyłącza wszystkie ads (banner + interstitial)
- Rewarded ads dalej są dostępne jako wybór ("get reward" nadal działa, ale bez oglądania)
- +50% offline earnings permanent
- Specjalny "Golden Theme" dla miasteczka (różowo-złoty pixel art)
- Specjalny manager "The Investor" (ekskluzywny)
- 100 IP starter pack

**Brak innych IAP.** Brak gemów, brak crystal, brak energy. Brak.

### 9.4. Przychody — projekcja

Przyjmując realistyczne metryki dla niche idle game:
- Dzienni aktywni użytkownicy (DAU): 500-5000 po 6 mies
- Ad eCPM (Polska/Europa Wschodnia): $2-5
- Ad eCPM (US/UK/DE): $10-25
- IAP conversion: 1-3%

**Projekcja przychodu:**
- 1000 DAU × 4 ads × $0.005 avg eCPM/imp = **$20/dzień = $600/mies**
- 1000 DAU × 2% × $5 IAP = $100/mies
- **Total: ~$700/mies przy 1000 DAU**

To realistic best-case dla solo dev. Większość idle games solo dev nigdy nie przekracza $200/mies. Twój cel "kilka stówek" jest osiągalny ale nie gwarantowany.


---

## 10. UI / UX

### 10.1. Główne ekrany

```
┌──────────────────────────────────────────┐
│  TOP BAR: $$$ | IP | Reputation | ⚙️    │
├──────────────────────────────────────────┤
│                                          │
│         CITY VIEW (top-down)            │
│       miasteczko z animowanymi          │
│       sklepami, klientami, NPC          │
│                                          │
│  Tap na sklep → szczegóły sklepu         │
│  Tap na puste pole → buy new shop        │
│                                          │
├──────────────────────────────────────────┤
│  CAMPAIGN BAR (bottom):                  │
│  [Flyers $5 ▲] [FB $50] [Google $80]    │
│  [Influencer $500] [TV $5k] [TikTok]     │
└──────────────────────────────────────────┘

Side menu (swipe lub button):
- Shops (lista wszystkich)
- Managers
- Tech Tree
- Achievements
- Stats
- Settings
- Leaderboards (Faza 3)
```

### 10.2. Detale UI

#### City View (główny widok):
- **Top-down 2D**, scroll/pinch dla zoomowania
- Sklepy to pixel buildings, każdy ma swój sprite per kategoria
- Klienci jako pixel sprite'y chodzące po ulicach (gdy success campaign)
- **Floating numbers** wylatują z każdego sklepu (klasyczne idle juice)
- Background zmienia się z prestige (vide sekcja 11)

#### Campaign Bar:
- 4-7 przycisków na dole (zależnie od odblokowanych)
- Każdy przycisk pokazuje: ikonę kampanii, koszt, cooldown bar
- Po kliknięciu — animacja "launch" (rocket lecący w niebo, lub TV z "ON AIR")
- Wynik animowany: 
  - Success → zielona "+X customers" floating text
  - Viral → ekran trzęsie się, częściciki, "VIRAL!" wielkimi literami
  - Mega viral → screen flash, special sound, "screenshot opportunity" overlay
  - Fail → szary "flop" tekst

#### Shop Detail (po kliknięciu sklepu):
- Modal popup
- Pokazuje: nazwa kategorii, level, current income/sec, capacity
- Przyciski: [Upgrade Level — $X], [Hire Manager], [Specialize]
- Stats: total earned z tego sklepu, customers served

#### Tech Tree:
- Pełny ekran, drzewo z 4 gałęziami
- Każdy node = ikonka + nazwa + koszt IP
- Locked nodes są szare, dostępne mają glow
- Tap → modal z opisem efektu + przyciskiem "Research"

### 10.3. Onboarding (Tutorial)

Pierwsza sesja gry, kontekstowy tutorial (nie modal "click here"):

1. **0:00-0:30:** Player widzi 1 sklep, tooltip "Tap shop to collect $$"
2. **0:30-1:00:** "You need more customers! Try Flyers" — tooltip na campaign bar
3. **1:00-2:00:** Pierwszy success campaign, tutorial pokazuje floating numbers
4. **2:00-5:00:** Otwieranie 2-go sklepu, manager pierwszego, upgrade
5. **5:00-15:00:** Free play, hints contextual
6. **30 min:** Pierwszy viral hit (skryptowany dla tutorialu — zwiększona szansa) — "WOW moment"
7. **1h:** Tutorial complete, teraz gra normalna

### 10.4. Notyfikacje

#### Push notifications (Faza 3, 1-2 dziennie max):
- **9:00 AM:** "Your offline earnings are full! Come collect" (jeśli >6h offline)
- **18:00:** "🎉 Trending Product Day in 1 hour! [Category]"
- **Special events:** Black Friday start, viral milestone, daily reward streak break warning

#### In-game notifications:
- Top right corner toast notifications
- "Manager Sara hired ✓"
- "New tech available!"
- "PR Crisis incoming!" (red, urgent)

### 10.5. Settings ekrany

- Sound on/off
- Music volume
- SFX volume
- Banner ads on/off (jeśli premium nie kupiony)
- Notifications on/off
- Language (Faza 3)
- Cloud save (Faza 3)
- Reset progress (z confirmation)
- Restore purchases
- Privacy policy / Terms

---

## 11. Asset Specification (Pixel Art 16-bit)

### 11.1. Wytyczne stylistyczne

- **Resolution:** 16x16 dla małych ikon, 32x32 dla budynków, 64x64 dla portretów managerów, 128x128 dla key art
- **Paleta kolorów:** ograniczona, ~32 kolory globalne (PICO-8 palette + extensions)
- **Outline style:** czarny 1px outline na wszystkich postaciach (klasyczny 16-bit feel)
- **Inspiracje:** Stardew Valley (overworld), Shovel Knight (UI), Owlboy (animacje), Eastward (tła)
- **Animacje:** 4-8 klatek max per animacja (loop)

### 11.2. Asset checklist (Faza 1 — MVP)

#### Tileset miasta:
- Trawa (3 wariacje)
- Chodnik (3 wariacje)
- Ulica (4 kierunki + skrzyżowania)
- Drzewa, krzaki, latarnie
- Płot, mur

#### Budynki (per kategoria, Faza 1 = 3 kategorie):
- Fashion store (3 levele wizualne — small / medium / mega)
- Tech store (3 levele)
- Food restaurant (3 levele)
- Magazyn (warehouse)
- Office HQ (gracza)

#### Postacie:
- Player avatar (gnome przedsiębiorca)
- Klient typ 1 (casual shopper) — 4 klatki walking animation
- Klient typ 2 (premium shopper)
- Klient typ 3 (kid/teen)
- 5 managerów (portret + walk animation)

#### UI elementy:
- Buttons (normal, pressed, disabled)
- Coin icon ($)
- Innovation Point icon (lightbulb)
- Star icon (reputation)
- Heart icon (love)
- Box/package icon
- Tech tree node icons (10 unique)

#### Effects:
- Money particle (coin spin animation, 4 frames)
- Star particle
- Smoke/explosion (campaign launch)
- "VIRAL" text effect
- Confetti

#### Backgrounds (per prestige tier):
- Wieś (grass, simple)
- Małe miasto (suburbia)
- Średnie miasto
- Metropolia
- Futurystyczne miasto (neon, hologramy)

### 11.3. AI generation workflow

**Strategia:** AI generuje base sprites, Aseprite cleanup do consistency.

#### Stable Diffusion (lokalnie, free):
- Model: **PixelArtRedmond** lub **AlbedoBase XL** z LoRA pixel art
- Prompt template: 
  ```
  pixel art, 16-bit style, [SUBJECT], 32x32 sprite, clean outline, 
  limited palette, side view / top-down view, transparent background,
  retro game aesthetic, no anti-aliasing
  ```
- Negative: `blurry, anti-aliased, modern, 3d, realistic, smooth`

#### Workflow per asset:
1. Generuj 4-8 wariantów AI
2. Wybierz najlepszy
3. Otwórz w Aseprite
4. Cleanup: usuń artefakty AA, popraw paletę do master palette
5. Eksport jako PNG z transparency
6. Dodaj do TexturePacker → atlas

**Estymowany czas per asset po opanowaniu:** 15-30 min.
**Total assets MVP:** ~80 unikalnych sprites.
**Total czas asset creation MVP:** ~30-40h.

### 11.4. Audio

#### Music:
- 1 utwór tła do menu (chill chiptune)
- 1 utwór gameplay (upbeat chiptune, loopable)
- 1 utwór "viral moment" (epicki short stinger)
- 1 utwór event special (np. Black Friday)
**Source:** Suno AI (subscription $10/mies) lub free chiptune music od OpenGameArt

#### SFX:
- Click button
- Coin collect (klasyczny)
- Cash register (sale)
- Whoosh (campaign launch)
- "VIRAL!" stinger
- "FAIL" stinger (sad trombone)
- Manager hired (jingle)
- Level up (achievement)
- New shop unlocked (fanfara)
- PR crisis warning (alarm)

**Source:** freesound.org (CC0), Pixabay sounds, sfxr/jsfxr (8-bit generator).


---

## 12. Architektura kodu (Godot)

### 12.1. Struktura projektu

```
capitalo/
├── project.godot
├── icon.svg
├── export_presets.cfg
├── assets/
│   ├── sprites/
│   │   ├── shops/
│   │   ├── customers/
│   │   ├── managers/
│   │   ├── ui/
│   │   └── effects/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── tilesets/
├── scenes/
│   ├── main/
│   │   ├── Main.tscn          # entry point
│   │   └── Main.gd
│   ├── city/
│   │   ├── CityView.tscn
│   │   ├── CityView.gd
│   │   ├── Shop.tscn
│   │   ├── Shop.gd
│   │   ├── Customer.tscn
│   │   └── Customer.gd
│   ├── ui/
│   │   ├── HUD.tscn
│   │   ├── HUD.gd
│   │   ├── CampaignBar.tscn
│   │   ├── CampaignBar.gd
│   │   ├── ShopDetailModal.tscn
│   │   ├── TechTree.tscn
│   │   └── ...
│   └── tutorial/
│       └── Tutorial.tscn
├── scripts/
│   ├── autoload/             # singletony (autoload w Godot)
│   │   ├── GameState.gd      # globalny stan gry
│   │   ├── EconomyManager.gd # liczy income, koszty
│   │   ├── CampaignSystem.gd # mechanika kampanii
│   │   ├── SaveSystem.gd     # save/load
│   │   ├── EventBus.gd       # signals globalne
│   │   ├── AudioManager.gd
│   │   └── AdsManager.gd     # AdMob integration
│   ├── classes/              # custom classes
│   │   ├── BigNumber.gd
│   │   ├── ShopData.gd
│   │   ├── ManagerData.gd
│   │   ├── CampaignData.gd
│   │   ├── TechNode.gd
│   │   └── Competitor.gd
│   └── utils/
│       ├── Formatters.gd     # number formatting
│       └── Math.gd
├── data/
│   ├── shops.json            # static data dla kategorii sklepów
│   ├── managers.json         # lista managerów + ich perks
│   ├── campaigns.json        # definicje kampanii
│   ├── tech_tree.json        # nodes definicje
│   ├── achievements.json
│   └── events.json           # sezonowe eventy
└── tests/
    └── ...
```

### 12.2. Autoloads (singletony)

#### GameState.gd
```gdscript
extends Node

# Stan globalny
var money: BigNumber = BigNumber.new(50)  # start z $50
var innovation_points: int = 0
var brand_reputation: float = 3.0  # 1-5 stars
var prestige_count: int = 0
var prestige_multiplier: float = 1.0

var shops: Array[ShopData] = []
var hired_managers: Array[ManagerData] = []
var unlocked_tech: Array[String] = []  # node IDs
var unlocked_categories: Array[String] = ["fashion"]

var session_start_time: int  # unix timestamp
var last_save_time: int

func _ready():
    SaveSystem.load_game()

func _process(delta: float):
    # Tick income calculation, etc.
    pass
```

#### EconomyManager.gd
```gdscript
extends Node

# Wszystkie obliczenia ekonomiczne
func calculate_shop_income(shop: ShopData) -> BigNumber:
    var base = SHOP_BASE_INCOME_BY_CATEGORY[shop.category]
    var level_mult = pow(SHOP_INCOME_GROWTH, shop.level)
    var manager_mult = shop.manager.get_total_multiplier() if shop.manager else 1.0
    var event_mult = EventManager.get_category_multiplier(shop.category)
    var rep_mult = 1.0 + (GameState.brand_reputation - 3.0) * 0.1  # 3 stars = neutral
    var prestige_mult = GameState.prestige_multiplier
    
    return BigNumber.new(base * level_mult * manager_mult * event_mult * rep_mult * prestige_mult)

func get_total_income_per_sec() -> BigNumber:
    var total = BigNumber.new(0)
    for shop in GameState.shops:
        total = total.add(calculate_shop_income(shop))
    return total

func process_income(delta: float):
    var income = get_total_income_per_sec().multiply_by_float(delta)
    GameState.money = GameState.money.add(income)
    EventBus.emit_signal("money_changed", GameState.money)
```

#### CampaignSystem.gd
```gdscript
extends Node

func launch_campaign(campaign_id: String) -> Dictionary:
    var campaign = CampaignData.get_by_id(campaign_id)
    
    # Validate
    if not _can_launch(campaign):
        return {"success": false, "reason": "cooldown_or_money"}
    
    # Deduct cost
    GameState.money = GameState.money.subtract(BigNumber.new(campaign.cost))
    
    # Roll
    var success_chance = campaign.base_success + _get_tech_success_modifier()
    var viral_chance = campaign.base_viral + _get_tech_viral_modifier()
    var roll = randf() * 100
    
    var result = {}
    if roll < viral_chance:
        result = _handle_viral(campaign)
    elif roll < success_chance:
        result = _handle_success(campaign)
    else:
        result = _handle_failure(campaign)
    
    EventBus.emit_signal("campaign_completed", campaign_id, result)
    return result

# ... handle_viral, handle_success, handle_failure
```

#### SaveSystem.gd
```gdscript
extends Node

const SAVE_PATH = "user://savegame.json"

func save_game():
    var save_dict = {
        "version": 1,
        "money": GameState.money.to_dict(),
        "innovation_points": GameState.innovation_points,
        "brand_reputation": GameState.brand_reputation,
        "shops": GameState.shops.map(func(s): return s.to_dict()),
        "hired_managers": GameState.hired_managers.map(func(m): return m.to_dict()),
        "unlocked_tech": GameState.unlocked_tech,
        "unlocked_categories": GameState.unlocked_categories,
        "prestige_count": GameState.prestige_count,
        "prestige_multiplier": GameState.prestige_multiplier,
        "last_save_time": Time.get_unix_time_from_system()
    }
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_dict))
    file.close()

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var save_dict = JSON.parse_string(file.get_as_text())
    file.close()
    
    if save_dict == null or save_dict.get("version", 0) != 1:
        # Migration logic for future versions
        return false
    
    # Restore state
    GameState.money = BigNumber.from_dict(save_dict.money)
    # ...
    
    # Calculate offline earnings
    var time_offline = Time.get_unix_time_from_system() - save_dict.last_save_time
    _apply_offline_earnings(time_offline)
    
    return true

func _apply_offline_earnings(seconds: int):
    var capped = min(seconds, OFFLINE_CAP_HOURS * 3600)
    var rate = EconomyManager.get_total_income_per_sec()
    var earnings = rate.multiply_by_float(capped * OFFLINE_EFFICIENCY)
    GameState.money = GameState.money.add(earnings)
    EventBus.emit_signal("offline_earnings_calculated", earnings, capped)
```

### 12.3. Signals (EventBus pattern)

Centralny EventBus dla luźnego sprzęgania:

```gdscript
# EventBus.gd
extends Node

signal money_changed(new_amount: BigNumber)
signal shop_purchased(shop: ShopData)
signal shop_upgraded(shop: ShopData)
signal manager_hired(manager: ManagerData)
signal campaign_launched(campaign_id: String)
signal campaign_completed(campaign_id: String, result: Dictionary)
signal tech_researched(node_id: String)
signal achievement_unlocked(achievement_id: String)
signal prestige_performed(ip_gained: int)
signal offline_earnings_calculated(amount: BigNumber, seconds: int)
signal viral_hit(campaign_id: String, multiplier: float)
signal pr_crisis_triggered(crisis: Dictionary)
signal reputation_changed(new_value: float)
```

### 12.4. Performance considerations

- **Tick rate:** Income calculation co 0.1s (10Hz), nie co frame (60Hz)
- **Customer sprites:** Object pooling — max 50 customers visible jednocześnie
- **Floating numbers:** Pool of 30 reusable labels
- **Save:** Co 30s auto-save w tle, plus on app pause
- **Offline calculation:** Done at boot, max 1 calculation regardless of offline duration
- **BigNumber:** Cache .to_display() string per second (nie regeneruj co frame)

### 12.5. Testing strategy

- **Unit tests:** BigNumber operations, income calculations, campaign rolls
- **Playtests:** Co tydzień, sam grasz przez 30-60 min, notuj friction points
- **Beta testers:** Faza 2, znajomi grają, dają feedback
- **Soft launch metrics:** Faza 2, real graczy w Polsce/Czechy/Rumunia, sprawdzasz retencję D1/D7/D30, ARPDAU


---

## 13. Plan implementacji dla Claude Code

### 13.1. Sprint 1 (Tydzień 1-2): Foundation

**Cel:** Działający projekt Godot z save system, BigNumber, podstawowy UI.

**Tasks dla Claude Code:**
1. Setup project Godot 4.x + git repo
2. Implementuj `BigNumber.gd` z testami
3. Implementuj `GameState.gd` (autoload)
4. Implementuj `SaveSystem.gd` (JSON, lokalny)
5. Implementuj `EventBus.gd`
6. Stwórz placeholder UI: HUD z money display, jeden sklep, jeden przycisk "Click"
7. Integracja: kliknięcie → +$1, money rośnie, auto-save działa, restart aplikacji = persistent

**Acceptance criteria:** Można odpalić grę, kliknąć 100 razy, zamknąć, otworzyć — kasa zachowana.

### 13.2. Sprint 2 (Tydzień 3-4): Core Loop

**Cel:** Marketing campaign system działa, sklepy generują pasywny income.

**Tasks dla Claude Code:**
1. `ShopData.gd` class + scena Shop
2. `EconomyManager.gd` z calculate_shop_income
3. Pasywny tick income (10Hz)
4. `CampaignData.gd` + JSON definitions (4 kampanie z Fazy 1)
5. `CampaignSystem.gd` z launch_campaign, mechaniką rolla
6. UI: CampaignBar z 4 przyciskami
7. Floating numbers system (object pool)
8. Customer spawning (basic, na success campaign)
9. Sound: click, coin, viral stinger

**Acceptance criteria:** Klikam Flyers → wydaje $5 → roll → spawn customers → income rośnie. Viral hit działa wizualnie i mechanicznie.

### 13.3. Sprint 3 (Tydzień 5-6): Shops & Managers

**Cel:** 3 kategorie sklepów, system upgrade'ów, managerowie.

**Tasks dla Claude Code:**
1. ShopDetailModal — UI per sklep
2. Shop level upgrade mechanic + cost calculation
3. Buy new shop mechanic
4. ManagerData class + JSON definitions
5. Hire manager flow (z kosztem)
6. Manager level upgrades (1-10)
7. Visual: pixel art assety dla 3 kategorii sklepów (lub placeholdery)
8. Animacja klientów wchodzących/wychodzących ze sklepu

**Acceptance criteria:** Mam Fashion shop, kupuję Tech, levleuję obie do Lvl 10, najmuję managera dla Fashion, manager Lvl 5. Wszystko persistent po save/load.

### 13.4. Sprint 4 (Tydzień 7-8): Tech Tree + Prestige

**Cel:** Pierwszy prestige cycle działa, tech tree gałąź Marketing.

**Tasks dla Claude Code:**
1. `TechNode.gd` class + JSON definitions (10 nodów Marketing)
2. TechTree UI (scrollable canvas z nodami)
3. Research mechanic (deduct IP, unlock node, apply effects)
4. Effects integration (modyfikatory do CampaignSystem, EconomyManager)
5. Prestige flow: warning modal → reset → IP gain calculation → multiplier applied
6. Prestige stats screen (total prestiges, IP earned, multiplier)

**Acceptance criteria:** Gram do $1B, klikam Prestige, dostaję IP, kupuję pierwszy node, restart gry, multiplier działa.

### 13.5. Sprint 5 (Tydzień 9-10): Polish & MVP Launch

**Cel:** MVP gotowy do wewnętrznego testowania (nie publicznego release).

**Tasks dla Claude Code:**
1. Tutorial system (kontekstowy hints)
2. Achievements system + 20 podstawowych achievementów
3. Settings ekran
4. Credits ekran
5. Stats ekran (total earned, time played, etc.)
6. Performance optimization
7. Bug fixes z playtestów
8. Eksport do Android APK (test na realnym telefonie)
9. Eksport do iOS (wymaga Mac + Xcode)

**Acceptance criteria:** Gra grywalna 5h+ bez bugów, instalowana na Twoim Androidzie i iPhone.

### 13.6. Następne sprinty (Faza 2-3)

Sprinty 6-15 obejmują:
- Pozostałe 7 kategorii sklepów
- 3 pozostałe gałęzie tech tree
- AI Competitors
- Eventy sezonowe
- Reputacja + PR Crises
- AdMob integration
- Soft launch
- Localization
- Social features (Faza 3)

Każdy sprint = 1-2 tygodnie pracy. Total ~20-30 sprintów do v1.0.

### 13.7. Promptowanie Claude Code

**Wzór dobrego prompta dla Claude Code:**
```
Cel: implementuj BigNumber.gd zgodnie z sekcją 8.4 GDD.

Kontekst:
- Godot 4.x, GDScript
- Klasa musi być `class_name BigNumber`
- Operacje: add, subtract, multiply, divide, multiply_by_float, compare
- Display format: "1.23K", "5.67M", "8.91B", etc. up to "1.00 Vg" (10^60+)
- Save/load: to_dict() i from_dict() static method

Pliki do stworzenia:
- scripts/classes/BigNumber.gd
- tests/BigNumberTest.gd (z asercjami)

Acceptance criteria:
- Wszystkie testy przechodzą
- Operacje są poprawne dla liczb 10^0 do 10^308
- Display format zgodny z idle game conventions
```

**Wzór złego prompta:** "Zrób BigNumber". (Za mało kontekstu, Claude Code będzie zgadywał.)

---

## 14. Ryzyka i mitigation

| Ryzyko | Prawdopodobieństwo | Impact | Mitigation |
|--------|--------------------|----|------------|
| Balans ekonomii zły, gra nudzi/za szybka | Wysokie | Wysoki | Spreadsheet symulacja PRZED kodem, playtest co tydzień |
| Pixel art assets niespójne wizualnie | Wysokie | Średni | Master palette zdefiniowana, każdy asset cleanup w Aseprite |
| App Store rejection | Średnie | Wysoki | Studiuj guidelines wcześnie, prepare wszystkie required things (privacy policy, screenshots, description) |
| Brak DAU po launch | Wysokie | Wysoki | Soft launch + ASO + organic content (TikTok dev journey, Reddit) |
| Burnout solo dev | Wysokie | Wysoki | Hard scope (Faza 1 = MVP), no scope creep, rest days |
| Godot bugs z mobile export | Średnie | Średni | Test exportów wcześnie, nie zostawiaj na koniec |
| AdMob problemy z verification | Niskie | Wysoki | Setup early, prepare test ads w Faza 2 |
| Player feedback "to nudne" | Średnie | Wysoki | Beta tester squad, A/B test najwcześniej możliwe |

---

## 15. Sukces — definicja

### MVP Success (Faza 1):
- [ ] Gra grywalna 5h+ bez crashy
- [ ] Core loop satysfakcjonujący
- [ ] Save/load działa
- [ ] Pierwszy prestige osiągalny w 5-10h gameplay (skompresowane dla testów)

### Soft Launch Success (Faza 2):
- [ ] D1 retention > 30%
- [ ] D7 retention > 10%
- [ ] Avg session length > 8 min
- [ ] No critical crashes (crash-free rate > 99%)
- [ ] Pierwsza sprzedaż IAP

### Global Launch Success (Faza 3):
- [ ] 1000+ downloads w pierwszym miesiącu
- [ ] 100+ DAU stable
- [ ] $50+ przychodu w pierwszym miesiącu
- [ ] 4.0+ rating na obu sklepach

### Long-term Success (Faza 4+):
- [ ] $200+ MRR
- [ ] 1000+ DAU
- [ ] 4.3+ rating
- [ ] Aktywna społeczność (Discord 100+ członków)

---

## 16. Załączniki (do stworzenia osobno)

Dokumenty do stworzenia obok tego GDD:
1. **shops.json** — pełne dane wszystkich kategorii sklepów (Faza 2 będzie miała 10)
2. **managers.json** — pełna lista 15-20 managerów z perks
3. **campaigns.json** — wszystkie kampanie z balansem
4. **tech_tree.json** — wszystkie nody (50) z efektami
5. **achievements.json** — 50 achievementów
6. **events.json** — sezonowe eventy z datami
7. **balance_sheet.xlsx** — symulacja ekonomii (zaprojektowanie krzywych przed kodem)
8. **art_style_guide.md** — szczegółowa paleta, examples, do/dont
9. **localization_keys.csv** — wszystkie teksty w grze (do tłumaczenia)

---

## 17. Open Questions / TODO przed rozpoczęciem

Kwestie do dyskusji z Arianem przed sprintem 1:

- [ ] Nazwa robocza vs final ("Capitalo" vs inne propozycje)
- [ ] Decyzja: Polski release tylko, czy globalne od dnia 1 (Faza 3 timing)
- [ ] Budget na muzykę: Suno AI vs free assets
- [ ] Decyzja: czy Mac (potrzebny do iOS build) — kupić, pożyczyć, czy MacBook in cloud (np. MacStadium)?
- [ ] App Store + Google Play developer accounts — kiedy zarejestrować ($99 + $25)
- [ ] Branding/marketing — kiedy zaczynamy presence (TikTok dev journey może budować audience pre-launch)

---

## END OF GDD v1.0

Ten dokument będzie ewoluował wraz z grą. Po każdej fazie aktualizujemy sekcje na podstawie real player data i playtestów.

**Każda zmiana mechaniczna w grze = update tego GDD przed wprowadzeniem zmiany w kodzie.** Document-driven development.
