--!strict
-- Tipos del modelo de datos de NEXORA.
-- Regla: SpeciesDefinition (Config/Species) es compartida e inmutable;
--        PetInstance es la criatura individual de un jugador (persistida en su perfil).

export type FormId = "Brote" | "Tallado"
export type StatId = "VID" | "ATQ" | "DEF" | "ESE" | "VEL"
export type Stats = { VID: number, ATQ: number, DEF: number, ESE: number, VEL: number }

export type AcquisitionSource = {
	kind: string, -- "Starter" | "Rescue" | "Breeding" | "Vitrina" | "Chest" | "Event" | "Dev"
	ref: string?,
	at: number,
}

export type PetTraits = {
	veta: string, -- color/material (Fase 2+)
	temple: string, -- "Neutro" en Fase 1
	don: string?,
	goldVein: boolean,
}

export type PetInstance = {
	id: string, -- único por cuenta: "U<userId>-<serial>"
	speciesId: string,
	form: FormId,
	level: number,
	xp: number, -- XP acumulada dentro del nivel actual
	bond: number, -- puntos de Vínculo
	nickname: string?,
	acquired: AcquisitionSource,
	traits: PetTraits,
	lineage: { generation: number, parents: { string }? },
	lastPlayedAt: number,
	evolvedAt: number?,
	loadout: { string }?, -- ids de movimiento equipados (nil = predeterminado)
	stats: { battlesWon: number, battlesLost: number, timesFed: number },
}

export type HabitatState = {
	id: string,
	slots: { string | false },
	level: number,
	lastCollectAt: number, -- última liquidación de producción
	accrued: number, -- Monedas liquidadas pendientes de recoger
	bonusCoins: number, -- reserva inicial de la primera recogida
}

export type PendingReward = {
	id: string,
	bundleId: string?,
	title: string,
	currencies: { [string]: number },
	items: { [string]: number },
	petXp: number,
	petIds: { string },
	unlocks: { string },
	source: { kind: string, ref: string, battleId: string? },
	createdAt: number,
}

export type Profile = {
	schemaVersion: number,
	userId: number,
	createdAt: number,
	lastLoginAt: number,
	loginCount: number,
	playSeconds: number,
	currencies: { [string]: number },
	items: { [string]: number },
	pets: { [string]: PetInstance },
	nextPetSerial: number,
	companionPetId: string?,
	team: { string },
	inventoryCapacity: number,
	lots: { [string]: { unlocked: boolean, habitats: { [string]: HabitatState } } },
	story: {
		cleared: { [string]: { firstClearAt: number, wins: number } },
		repeatDay: number,
		repeatCount: number,
	},
	onboarding: { step: string, completed: boolean, introSkipped: boolean?, startedAt: number },
	unlocks: { [string]: number },
	rewards: { pending: { [string]: PendingReward }, ledger: { [string]: number }, ledgerOrder: { string } },
	firsts: { [string]: number },
	counters: { [string]: number },
}

return {}
