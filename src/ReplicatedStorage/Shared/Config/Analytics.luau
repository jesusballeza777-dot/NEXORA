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
		"session_start",
		"session_end",
		"data_save_status",
		"unlock_granted",
		"sanctuary_visit",
		"coins_collected",
		"food_purchased",
		"battle_started",
		"battle_finished",
		"pet_evolved",
		"remote_rejected",
	},
})
