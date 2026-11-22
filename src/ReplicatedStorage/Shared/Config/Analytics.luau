--!strict
-- Eventos de analítica (Biblia compacta p. 8 y Genesis §10). Los "first_*" se
-- registran una sola vez por cuenta (marcados en el perfil).

local Freeze = require(script.Parent.Parent.Util.Freeze)

return Freeze.deep({
	-- Embudo de onboarding en orden (AnalyticsService:LogOnboardingFunnelStepEvent)
	OnboardingFunnel = {
		"onboarding_started",
		"intro_finished", -- con campo skipped = true/false
		"starter_egg_selected",
		"hatch_completed",
		"pet_follow_started",
		"habitat_opened",
		"first_feed",
		"first_bond_gain",
		"first_battle_started",
		"first_battle_completed",
		"first_reward_claimed",
		"tutorial_completed",
	},
	Events = {
		"session_started",
		"session_ended",
		"data_save_status",
		"unlock_granted",
		"sanctuary_visit",
		"coins_collected",
		"food_purchased",
		"battle_started",
		"battle_finished",
		"pet_evolved",
		"remote_rejected",
		-- Fase 2 (Genesis F2 §20)
		"species_discovered",
		"egg_obtained",
		"incubation_started",
		"incubation_completed",
		"egg_hatched",
		"chest_obtained",
		"chest_opened",
		"quest_started",
		"quest_completed",
		"quest_claimed",
		"adventure_stage_started",
		"adventure_stage_completed",
		"stage_star_earned",
		"opaco_restored",
		"guardian_battle_started",
		"guardian_defeated",
		"codex_entry_unlocked",
		"sanctuary_updated",
	},
	-- Hitos de una sola vez (p.firsts) con los segundos desde la creación de la cuenta:
	-- tiempo hasta la 2.ª criatura, 1.ª eclosión, 1.ª evolución y 1.ª etapa superada.
	Milestones = { "second_creature", "first_hatch", "first_evolution", "first_stage_completed" },
})
