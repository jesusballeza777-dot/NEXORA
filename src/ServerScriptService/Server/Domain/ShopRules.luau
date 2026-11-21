--!strict
-- Despensa del Gabinete: compra determinista de comida con Monedas ganadas jugando.
-- No hay productos de Robux, ni aleatoriedad, ni Gemas en la Fase 1.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Types = require(Shared.Types)
local Result = require(script.Parent.Result)

type Profile = Types.Profile

local ShopRules = {}

function ShopRules.buyFood(p: Profile, foodId: string, quantity: number): Result.Result
	local food = Economy.Foods[foodId]
	if not food or not food.sold then
		return Result.fail("NotForSale")
	end
	if math.floor(quantity) ~= quantity or quantity < 1 or quantity > Economy.MaxPurchaseQuantity then
		return Result.fail("BadQuantity")
	end
	if (p.items[foodId] or 0) + quantity > Economy.MaxItemStack then
		return Result.fail("StackFull")
	end
	for cur, price in pairs(food.price) do
		if (p.currencies[cur] or 0) < price * quantity then
			return Result.fail("NotEnough" .. cur)
		end
	end
	for cur, price in pairs(food.price) do
		p.currencies[cur] -= price * quantity
	end
	p.items[foodId] = (p.items[foodId] or 0) + quantity
	return Result.ok({ foodId = foodId, quantity = quantity, owned = p.items[foodId], balance = p.currencies })
end

return ShopRules
