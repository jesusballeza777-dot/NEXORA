--!strict
-- Integración de mallas importadas (D-040) con clases reales de @lune/roblox:
-- * sin modelo en ReplicatedStorage.CreatureModels → CreatureBuilder usa el blockout;
-- * con modelo → la criatura usa la malla (mesh = true), el Opaco tiñe SurfaceAppearance
--   y CreatureAnimator anima los Bone por nombre.
-- El modelo importado se simula aquí (Studio no está disponible): no valida el importador.
local T = harness.T
local expect = T.expect
local roblox = harness.sandbox.roblox

local function fakeImported(): any
	local model = roblox.Instance.new("Model")
	model.Name = "CR_Kuachi_Brote_v01"
	local mp = roblox.Instance.new("MeshPart")
	mp.Name = "CR_Kuachi_Brote_v01"
	mp.Size = roblox.Vector3.new(1, 1.7, 2.3)
	mp.Parent = model
	model.PrimaryPart = mp
	local sa = roblox.Instance.new("SurfaceAppearance")
	sa.Parent = mp
	for _, name in ipairs({
		"root",
		"spine",
		"chest",
		"head",
		"jaw",
		"legF_L",
		"legF_R",
		"legB_L",
		"legB_R",
		"tail1",
		"tail2",
		"tail3",
	}) do
		local b = roblox.Instance.new("Bone")
		b.Name = name
		b.Parent = mp
	end
	return model
end

local function client(withModel: boolean)
	local stub = {
		asset = function()
			return nil
		end,
		template = function()
			return nil
		end,
		build = function(speciesId: string, form: string)
			if withModel and speciesId == "kuachi" and form == "Brote" then
				return fakeImported()
			end
			return nil
		end,
	}
	local sb = harness.sandbox.newClient({ ["Client.Creatures.MeshCreature"] = stub })
	return sb.load("StarterPlayerScripts.Client.Creatures.CreatureBuilder"),
		sb.load("StarterPlayerScripts.Client.Animation.CreatureAnimator")
end

T.describe("Mallas importadas (MeshCreature → CreatureBuilder)", function()
	T.it("sin modelo importado se usa el blockout de siempre", function()
		local CreatureBuilder = client(false)
		local folder = roblox.Instance.new("Folder")
		local c = CreatureBuilder.build("kuachi", "Brote", { parent = folder })
		expect(c.mesh).toBe(nil)
		expect(#c.parts > 5).toBe(true)
		c:destroy()
	end)

	T.it("con modelo importado se usa la malla, el Opaco tiñe SurfaceAppearance y anima huesos", function()
		local CreatureBuilder, CreatureAnimator = client(true)
		local folder = roblox.Instance.new("Folder")
		local c = CreatureBuilder.build("kuachi", "Brote", { parent = folder, opaco = true })
		expect(c.mesh).toBe(true)
		expect(c.scale).toBe(1)
		expect(#c.parts).toBe(1)
		local sa = c.parts[1].part:FindFirstChildOfClass("SurfaceAppearance")
		expect(sa.Color ~= roblox.Color3.new(1, 1, 1)).toBe(true)
		CreatureBuilder.setOpaco(c, 0)
		expect(sa.Color == roblox.Color3.new(1, 1, 1)).toBe(true)
		local anim = CreatureAnimator.new(c)
		expect(anim.mesh).toBe(true)
		-- las demás especies siguen con su blockout
		local other = CreatureBuilder.build("teselo", "Brote", { parent = folder })
		expect(other.mesh).toBe(nil)
		c:destroy()
		other:destroy()
	end)
end)
