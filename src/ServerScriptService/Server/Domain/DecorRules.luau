--!strict
-- Santuario ampliado (Fase 2): decoración en 6 espacios, plantillas de un toque,
-- vitrina de exhibición y ampliación del Vivero.
-- * Solo se colocan objetos que el jugador posee (validado aquí, en el servidor).
-- * Un objeto poseído puede estar en tantos espacios como copias tenga.
-- * La vitrina muestra hasta Sanctuary.VitrinaSlots monstruos del propio jugador.
-- * Vivero: +10 lugares por 5 000 Monedas hasta 100 (Config/Sanctuary, p. 30).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Decor = require(Shared.Config.Decor)
local Sanctuary = require(Shared.Config.Sanctuary)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)

type Profile = Types.Profile

local DecorRules = {}

local function usedCopies(p: Profile, decorId: string, exceptSlot: number?): number
	local n = 0
	for i, id in ipairs(p.decor.slots) do
		if id == decorId and i ~= exceptSlot then
			n += 1
		end
	end
	return n
end

function DecorRules.grant(p: Profile, decorId: string, amount: number?): Result.Result
	if not Decor.ById[decorId] then
		return Result.fail("UnknownDecor")
	end
	p.decor.owned[decorId] = (p.decor.owned[decorId] or 0) + (amount or 1)
	return Result.ok({ decorId = decorId })
end

-- decorId = nil vacía el espacio
function DecorRules.place(p: Profile, slot: number, decorId: string?): Result.Result
	if slot < 1 or slot > Decor.FreeSlots or math.floor(slot) ~= slot then
		return Result.fail("BadSlot")
	end
	if not p.lots.Hogar or not p.lots.Hogar.unlocked then
		return Result.fail("LotLocked")
	end
	if decorId == nil or decorId == "" then
		p.decor.slots[slot] = false
		return Result.ok({ slot = slot })
	end
	if not Decor.ById[decorId :: string] then
		return Result.fail("UnknownDecor")
	end
	local owned = p.decor.owned[decorId :: string] or 0
	if usedCopies(p, decorId :: string, slot) >= owned then
		return Result.fail("DecorNotOwned")
	end
	p.decor.slots[slot] = decorId :: string
	return Result.ok({ slot = slot, decorId = decorId })
end

-- Plantilla: coloca sus objetos en los primeros espacios libres (solo los que posee)
function DecorRules.applyTemplate(p: Profile, templateId: string): Result.Result
	local template = nil
	for _, t in ipairs(Decor.Templates) do
		if t.id == templateId then
			template = t
		end
	end
	if not template then
		return Result.fail("UnknownTemplate")
	end
	local placed = {}
	for _, decorId in ipairs(template.slots) do
		for slot = 1, Decor.FreeSlots do
			if p.decor.slots[slot] == false then
				if DecorRules.place(p, slot, decorId).ok then
					table.insert(placed, slot)
				end
				break
			end
		end
	end
	if #placed == 0 then
		return Result.fail("NothingPlaced")
	end
	return Result.ok({ placed = placed })
end

function DecorRules.setShowcase(p: Profile, petIds: { string }): Result.Result
	if #petIds > Sanctuary.VitrinaSlots then
		return Result.fail("TooManyPets")
	end
	local seen: { [string]: boolean } = {}
	for _, id in ipairs(petIds) do
		if not p.pets[id] then
			return Result.fail("PetNotOwned")
		end
		if seen[id] then
			return Result.fail("DuplicatePet")
		end
		seen[id] = true
	end
	p.showcase = table.clone(petIds)
	return Result.ok({ showcase = p.showcase })
end

function DecorRules.expandInventory(p: Profile): Result.Result
	if p.inventoryCapacity >= Sanctuary.InventoryMaxCapacity then
		return Result.fail("InventoryAtMax")
	end
	local rule = Sanctuary.InventoryExpansion
	local cost = rule.price.Monedas
	if (p.currencies.Monedas or 0) < cost then
		return Result.fail("NotEnoughMonedas")
	end
	p.currencies.Monedas -= cost
	p.inventoryCapacity = math.min(Sanctuary.InventoryMaxCapacity, p.inventoryCapacity + rule.step)
	return Result.ok({ capacity = p.inventoryCapacity, cost = cost })
end

return DecorRules
