--!strict
-- Мінімальна реалізація сигналу. Обробники запускаються через task.spawn,
-- тому помилка в одному не ламає решту.

export type Signal = {
	connect: (self: Signal, fn: (...any) -> ()) -> () -> (),
	fire: (self: Signal, ...any) -> (),
}

local Signal = {}

function Signal.new(): Signal
	local handlers: { (...any) -> () } = {}
	return {
		connect = function(_self: Signal, fn: (...any) -> ()): () -> ()
			table.insert(handlers, fn)
			return function()
				local index = table.find(handlers, fn)
				if index then
					table.remove(handlers, index)
				end
			end
		end,
		fire = function(_self: Signal, ...: any)
			for _, fn in table.clone(handlers) do
				task.spawn(fn, ...)
			end
		end,
	}
end

return Signal
