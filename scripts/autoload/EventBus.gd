## EventBus.gd
## Global signal hub. AUTOLOAD as "EventBus".
##
## Pattern: dowolny system w grze emituje sygnał przez EventBus,
## inni słuchają. Dzięki temu nie ma sztywnych referencji między systemami.
##
## Usage:
##   # Emit:
##   EventBus.money_changed.emit(new_money)
##
##   # Listen:
##   func _ready():
##       EventBus.money_changed.connect(_on_money_changed)
##
## CRITICAL: Wszystkie sygnały deklaruj TUTAJ. Łatwiej śledzić co się dzieje w grze.
## CRITICAL: Nie pakuj logiki do EventBus — to tylko hub do sygnałów.

extends Node

# ==========================================================================
# ECONOMY SIGNALS
# ==========================================================================

## Emitowany za każdym razem gdy zmienia się stan kasy.
## param: new_money: BigNumber
signal money_changed(new_money)

## Emitowany gdy gracz zarobi z konkretnego sklepu (do floating numbers).
## param: shop_id: String, amount: BigNumber
signal shop_earned(shop_id, amount)

## Emitowany gdy zmieni się total income per second.
## param: new_ips: BigNumber
signal income_per_second_changed(new_ips)


# ==========================================================================
# SHOP SIGNALS
# ==========================================================================

## Sklep został kupiony (pierwszy raz odblokowany).
## param: shop_id: String
signal shop_purchased(shop_id)

## Sklep został ulepszony (level up).
## param: shop_id: String, new_level: int
signal shop_upgraded(shop_id, new_level)

## Specjalizacja została wybrana dla sklepu.
## param: shop_id: String, spec_id: String
signal shop_specialization_chosen(shop_id, spec_id)

## Gracz tapnął slot sklepu w CityView (do logiki buy/upgrade).
## param: shop_id: String, slot_state: String ("empty" / "owned")
signal shop_slot_tapped(shop_id, slot_state)

## Próba zakupu/upgrade nie powiodła się (np. brak kasy).
## param: shop_id: String, reason: String ("insufficient_funds" / "invalid_shop")
signal shop_purchase_failed(shop_id, reason)


# ==========================================================================
# MANAGER SIGNALS
# ==========================================================================

## Manager został zatrudniony.
## param: manager_id: String
signal manager_hired(manager_id)

## Manager został awansowany (upgrade).
## param: manager_id: String, new_level: int
signal manager_upgraded(manager_id, new_level)


# ==========================================================================
# CAMPAIGN SIGNALS
# ==========================================================================

## Kampania marketingowa została odpalona.
## param: campaign_id: String
signal campaign_launched(campaign_id)

## Kampania zakończona — wynik (success/viral/fail).
## param: campaign_id: String, result: String ("success" / "viral" / "fail"), payout: BigNumber
signal campaign_completed(campaign_id, result, payout)

## Specjalny event: VIRAL HIT! (do screen shake, particles, sound).
## param: campaign_id: String, multiplier: float
signal viral_hit(campaign_id, multiplier)


# ==========================================================================
# TECH TREE SIGNALS
# ==========================================================================

## Innovation Points się zmieniły.
## param: new_ip: int
signal innovation_points_changed(new_ip)

## Tech node został odblokowany.
## param: node_id: String
signal tech_node_unlocked(node_id)


# ==========================================================================
# PRESTIGE SIGNALS
# ==========================================================================

## Gracz odpalił prestige (reset z bonusem).
## param: ip_earned: int, prestige_count: int
signal prestige_performed(ip_earned, prestige_count)

## Multiplier prestige się zmienił.
## param: new_multiplier: float
signal prestige_multiplier_changed(new_multiplier)


# ==========================================================================
# GAME STATE SIGNALS
# ==========================================================================

## Gra się załadowała (po SaveSystem.load_game).
signal game_loaded

## Gra została zapisana.
signal game_saved

## Offline earnings policzone i wypłacone.
## param: amount: BigNumber, offline_seconds: float
signal offline_earnings_paid(amount, offline_seconds)


# ==========================================================================
# UI SIGNALS
# ==========================================================================

## Gracz tapnął ekran (do click campaigns).
## param: position: Vector2 (screen coords)
signal screen_tapped(position)

## Modal został otwarty.
## param: modal_name: String
signal modal_opened(modal_name)

## Modal został zamknięty.
## param: modal_name: String
signal modal_closed(modal_name)

## Achievement został odblokowany.
## param: achievement_id: String
signal achievement_unlocked(achievement_id)

## Gracz nacisnął przycisk Settings w HUD.
signal settings_requested

## Tutorial step został wyświetlony graczowi.
## param: step_id: String
signal tutorial_step_shown(step_id)

## Tutorial step został ukończony (dismiss przez gracza).
## param: step_id: String
signal tutorial_step_completed(step_id)


# ==========================================================================
# AI COMPETITORS / LIVE WORLD
# ==========================================================================

## Konkurent zrobił agresywny ruch (np. otworzył sklep tej samej kategorii).
## param: competitor_id: String, action_type: String
signal competitor_action(competitor_id, action_type)

## Sezonowy event się rozpoczął.
## param: event_id: String
signal event_started(event_id)

## Sezonowy event się skończył.
## param: event_id: String
signal event_ended(event_id)

## PR Crisis się zaczął — wymaga decyzji gracza.
## param: crisis_id: String
signal pr_crisis_triggered(crisis_id)

## Reputacja się zmieniła.
## param: new_reputation: int (0-100)
signal reputation_changed(new_reputation)


# ==========================================================================
# DEBUG
# ==========================================================================

func _ready() -> void:
	print("[EventBus] Initialized — listening for all game events")
