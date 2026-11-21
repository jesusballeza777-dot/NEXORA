--!strict
-- Registro estructurado mínimo. En producción, los errores también se envían a
-- AnalyticsTracker como "server_error" para detectarlos en Creator Analytics.

local Log = {}

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }
Log.level = 2

local sinks: { (level: string, scope: string, message: string) -> () } = {}

function Log.addSink(fn: (level: string, scope: string, message: string) -> ())
	table.insert(sinks, fn)
end

local function write(level: string, scope: string, message: string)
	if LEVELS[level] < Log.level then
		return
	end
	local line = string.format("[NEXORA][%s][%s] %s", string.upper(level), scope, message)
	if level == "warn" or level == "error" then
		warn(line)
	else
		print(line)
	end
	for _, sink in ipairs(sinks) do
		pcall(sink, level, scope, message)
	end
end

function Log.scope(scope: string)
	return {
		debug = function(fmt: string, ...: any)
			write("debug", scope, string.format(fmt, ...))
		end,
		info = function(fmt: string, ...: any)
			write("info", scope, string.format(fmt, ...))
		end,
		warn = function(fmt: string, ...: any)
			write("warn", scope, string.format(fmt, ...))
		end,
		error = function(fmt: string, ...: any)
			write("error", scope, string.format(fmt, ...))
		end,
	}
end

return Log
