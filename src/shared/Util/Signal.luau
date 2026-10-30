--!strict
-- Минимальная реализация сигнала. Обработчики запускаются через task.spawn,
-- поэтому ошибка в одном не ломает остальные.

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
