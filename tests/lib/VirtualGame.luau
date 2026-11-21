--!strict
-- Árbol de instancias virtual que emula lo que Rojo genera desde src/
-- (default.project.json) y un require() compatible con require(script.Parent.X).
-- Lo usan tests/runner.luau y tools/web-preview/build.luau.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local ROOT = process.cwd
if string.sub(ROOT, -1) ~= "/" then
	ROOT ..= "/"
end

-- ------------------------------------------------------------------
-- Árbol de instancias virtual
-- ------------------------------------------------------------------
type Node = { [string]: any }

local NodeMeta = {}
NodeMeta.__index = function(self: Node, key: string)
	local children = rawget(self, "_children")
	if children and children[key] then
		return children[key]
	end
	local method = NodeMeta.methods[key]
	if method then
		return method
	end
	error(string.format("%s no es miembro válido de %s", tostring(key), rawget(self, "Name")), 2)
end
NodeMeta.__tostring = function(self: Node)
	return rawget(self, "Name")
end
NodeMeta.methods = {
	FindFirstChild = function(self: Node, name: string)
		return rawget(self, "_children")[name]
	end,
	WaitForChild = function(self: Node, name: string)
		local c = rawget(self, "_children")[name]
		if not c then
			error("WaitForChild: no existe " .. name .. " en " .. rawget(self, "Name"))
		end
		return c
	end,
	GetChildren = function(self: Node)
		local out = {}
		for _, c in pairs(rawget(self, "_children")) do
			table.insert(out, c)
		end
		return out
	end,
	IsA = function(self: Node, className: string)
		return rawget(self, "ClassName") == className
	end,
	GetFullName = function(self: Node)
		local parts = {}
		local n: Node? = self
		while n and rawget(n, "ClassName") ~= "DataModel" do
			table.insert(parts, 1, rawget(n, "Name"))
			n = rawget(n, "Parent")
		end
		return table.concat(parts, ".")
	end,
	GetService = function(self: Node, name: string)
		local c = rawget(self, "_children")[name]
		if not c then
			error("Servicio no emulado: " .. name)
		end
		return c
	end,
}

local function newNode(name: string, className: string, parent: Node?, file: string?): Node
	local node =
		setmetatable({ Name = name, ClassName = className, Parent = parent, _children = {}, _file = file }, NodeMeta)
	if parent then
		rawget(parent, "_children")[name] = node
	end
	return node
end

local function stripExt(name: string): (string, string)
	for _, suffix in ipairs({ ".server.luau", ".client.luau", ".luau", ".server.lua", ".client.lua", ".lua" }) do
		if string.sub(name, -#suffix) == suffix then
			local base = string.sub(name, 1, -#suffix - 1)
			if string.find(suffix, "server") then
				return base, "Script"
			elseif string.find(suffix, "client") then
				return base, "LocalScript"
			end
			return base, "ModuleScript"
		end
	end
	return name, "Folder"
end

local function mount(dir: string, parent: Node)
	for _, entry in ipairs(fs.readDir(dir)) do
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			local init = nil
			for _, candidate in ipairs({ "init.luau", "init.lua" }) do
				if fs.isFile(path .. "/" .. candidate) then
					init = path .. "/" .. candidate
				end
			end
			local node = newNode(entry, if init then "ModuleScript" else "Folder", parent, init)
			mount(path, node)
		elseif not string.match(entry, "^init%.") then
			local name, className = stripExt(entry)
			if className ~= "Folder" then
				newNode(name, className, parent, path)
			end
		end
	end
end

local game = newNode("Game", "DataModel", nil, nil)
local mapping = {
	ReplicatedStorage = "src/ReplicatedStorage",
	ServerScriptService = "src/ServerScriptService",
	StarterPlayerScripts = "src/StarterPlayer/StarterPlayerScripts",
}
for service, path in pairs(mapping) do
	local node =
		newNode(service, if service == "StarterPlayerScripts" then "StarterPlayerScripts" else service, game, nil)
	if fs.isDir(ROOT .. path) then
		mount(ROOT .. path, node)
	end
end

-- ------------------------------------------------------------------
-- require() emulado
-- ------------------------------------------------------------------
local cache: { [Node]: any } = {}
local loading: { [Node]: boolean } = {}
local harnessRequire

local function loadFile(file: string, scriptNode: Node, extraEnv: { [string]: any }?): any
	local source = fs.readFile(file)
	local env = { script = scriptNode, require = harnessRequire, game = game }
	if extraEnv then
		for k, v in pairs(extraEnv) do
			env[k] = v
		end
	end
	local chunk = luau.load(source, { debugName = string.gsub(file, "^" .. ROOT, ""), environment = env })
	return chunk()
end

harnessRequire = function(target: any): any
	if type(target) == "string" then
		return require(target)
	end
	local node = target :: Node
	assert(rawget(node, "ClassName") == "ModuleScript", "require() de algo que no es ModuleScript: " .. tostring(node))
	if cache[node] ~= nil then
		return cache[node]
	end
	assert(not loading[node], "Dependencia circular en " .. node:GetFullName())
	loading[node] = true
	local result = loadFile(rawget(node, "_file"), node)
	loading[node] = nil
	assert(result ~= nil, "El módulo no devolvió valor: " .. node:GetFullName())
	cache[node] = result
	return result
end

local function getModule(path: string): any
	local node: any = game
	for part in string.gmatch(path, "[^%.]+") do
		node = node:WaitForChild(part)
	end
	return harnessRequire(node)
end

return {
	ROOT = ROOT,
	game = game,
	require = harnessRequire,
	get = getModule,
	loadFile = loadFile,
	newNode = newNode,
}
