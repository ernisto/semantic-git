local luau = require('@lune/luau')

-- class
local env = {}
export type env = {
	extends: (env: env, new_data: { [string]: any }) -> env,
	compute: (env: env, field: placeholder) -> any,
	compute_fields: (env: env, fields: { placeholder }) -> { string },
	date: (env: env, date_pattern: string) -> string,
}

-- constructor
function env.extends(parent: env, new_data: { [string]: any }): env
	local env = setmetatable(table.clone(new_data), { __index = parent })
	return table.freeze(env) :: any
end

-- compute
export type luau_expr = string
export type placeholder = string | '${luau_expr}'

local function eval(env: env, expr: luau_expr): any
	local success, result = pcall(luau.load, `return {expr}`, { environment = env })
	if not success then
		-- print(result)
		local syntax_err = string.match(tostring(result), 'syntax error: %[string %b""%]:%d+: (.+)')
		error(`invalid expression '{expr}': {syntax_err or 'unknown'}`)
	end
	success, result = pcall(result)
	if not success then
		local runtime_err = string.match(tostring(result), '%[string %b""%]:%d+: (.+)')
		error(`error occurred evaluating expression '{expr}': {runtime_err or 'unknown'}`)
	end
	return result
end
function env.compute(env: env, field: placeholder): any
	return if string.match(field, '^$%b{}$')
		then eval(env, string.sub(field, 3, -2))
		else string.gsub(field, '($%b{})', function(field)
			return tostring(env:compute(field))
		end)
end
function env.compute_fields(env: env, fields: { placeholder }): { string }
	local output = table.clone(fields)
	for index, field in fields do
		output[index] = tostring(env:compute(field))
	end
	return output :: any
end

-- misc
function env.date(env: env, date_pattern: string): string
	return os.date(#date_pattern > 0 and date_pattern or '%m.%d')
end

-- module
return table.freeze(env)
