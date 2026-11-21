--!strict
-- Plantillas de rol en % del presupuesto (Biblia v5.0 p. 35, DEFINIDO).
-- Se usan para validar el reparto de cada especie y para generar Opacos genéricos.

local Freeze = require(script.Parent.Parent.Util.Freeze)

export type RoleId = "Atacante" | "Defensor" | "Soporte" | "Control" | "Veloz" | "Bruto" | "Adaptativo"

export type RoleDef = {
	id: RoleId,
	template: { VID: number, ATQ: number, DEF: number, ESE: number, VEL: number },
	style: string,
}

local Roles: { [string]: RoleDef } = {
	Atacante = {
		id = "Atacante",
		template = { VID = 19, ATQ = 27, DEF = 15, ESE = 18, VEL = 21 },
		style = "Golpea fuerte y rápido; frágil si recibe primero.",
	},
	Defensor = {
		id = "Defensor",
		template = { VID = 25, ATQ = 16, DEF = 28, ESE = 16, VEL = 15 },
		style = "Aguanta y protege; gana por desgaste.",
	},
	Soporte = {
		id = "Soporte",
		template = { VID = 23, ATQ = 14, DEF = 19, ESE = 27, VEL = 17 },
		style = "Cura, protege y mejora al aliado.",
	},
	Control = {
		id = "Control",
		template = { VID = 19, ATQ = 15, DEF = 18, ESE = 26, VEL = 22 },
		style = "Estados, lentitud y negación de Savia.",
	},
	Veloz = {
		id = "Veloz",
		template = { VID = 17, ATQ = 22, DEF = 14, ESE = 18, VEL = 29 },
		style = "Actúa primero y remata.",
	},
	Bruto = {
		id = "Bruto",
		template = { VID = 24, ATQ = 25, DEF = 21, ESE = 12, VEL = 18 },
		style = "Cuerpo grande y golpe pesado, poca Esencia.",
	},
	Adaptativo = {
		id = "Adaptativo",
		template = { VID = 20, ATQ = 20, DEF = 20, ESE = 20, VEL = 20 },
		style = "Sin punto débil ni punto fuerte.",
	},
}

return Freeze.deep({ ById = Roles })
