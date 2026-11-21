--!strict
-- Espejo local de la vista del perfil (ProfileView) que envía el servidor.
-- Es de solo lectura para la interfaz: cualquier cambio real pasa por Net.request.

local State = {}

State.view = nil :: any
local changed = Instance.new("BindableEvent")
State.Changed = changed.Event

function State.set(view: any)
	State.view = view
	changed:Fire(view)
end

function State.pet(petId: string?): any?
	if not State.view or not petId then
		return nil
	end
	for _, pet in ipairs(State.view.pets) do
		if pet.id == petId then
			return pet
		end
	end
	return nil
end

function State.companion(): any?
	return if State.view then State.pet(State.view.companionPetId) else nil
end

function State.step(): string
	return if State.view then State.view.onboarding.step else "Intro"
end

return State
