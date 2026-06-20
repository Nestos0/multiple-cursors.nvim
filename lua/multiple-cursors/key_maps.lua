local M = {}

local virtual_cursors = require("multiple-cursors.virtual_cursors")
local common = require("multiple-cursors.common")
local input = require("multiple-cursors.input")

-- A table of key maps
-- {key(s), function_name_string}
local entire_key_maps = {}

-- Custom key maps
-- {mode(s), key(s), function_or_name}
local custom_key_maps = {}

-- Function registry: name -> {fn = function, mode = string|table}
local function_registry = {}

-- A table to store any existing key maps so that they can be restored
-- mode, dict
local existing_key_maps = {}

local function flatten_keymaps(maps)
	local flattened = {}
	for _, entry in ipairs(maps) do
		local key_spec = entry[1]
		local action = entry[2]

		-- 如果第一个元素是 table（代表复合 key），则展开
		if type(key_spec) == "table" then
			for _, key in ipairs(key_spec) do
				table.insert(flattened, { key, action })
			end
		else
			table.insert(flattened, vim.deepcopy(entry))
		end
	end
	return flattened
end

local function merge_keymaps(_default_maps, _custom_maps)
	if not next(_custom_maps) then
		return _default_maps
	end

	local entire = {}

	-- action => {map1, map2, ...}
	local custom_index = {}

	for _, entry in ipairs(_custom_maps) do
		local action = entry[1]

		custom_index[action] = custom_index[action] or {}
		table.insert(custom_index[action], vim.deepcopy(entry))
	end

	for _, entry in ipairs(_default_maps) do
		local action = entry[1]

		if custom_index[action] then
			vim.list_extend(entire, custom_index[action])

			custom_index[action] = nil
		else
			table.insert(entire, vim.deepcopy(entry))
		end
	end

	for _, maps in pairs(custom_index) do
		vim.list_extend(entire, maps)
	end

	return entire
end

function M.setup(_default_key_maps, _custom_key_maps, _function_registry)
	function_registry = _function_registry
	entire_key_maps = merge_keymaps(flatten_keymaps(_default_key_maps), _custom_key_maps)
	custom_key_maps = _custom_key_maps
end

function M.has_custom_keys_maps()
	return next(custom_key_maps) ~= nil
end

-- Return x in a table if it isn't already a table
local function wrap_in_table(x)
	if type(x) == "table" then
		return x
	else
		return { x }
	end
end

-- Check if a default function is overridden by a custom key map
-- Override happens when a custom entry's 3rd element (string) matches the default's name
local function is_default_allowed(name)
	if next(custom_key_maps) == nil then
		return true
	end
	for _, c in ipairs(custom_key_maps) do
		if type(c[3]) == "string" and c[3] == name then
			return false
		end
	end
	return true
end

-- Save a single key map
local function save_existing_key_map(mode, key)
	local dict = vim.fn.maparg(key, mode, false, true)
	if dict["buffer"] == 1 then
		table.insert(existing_key_maps, { mode, dict })
	end
end

-- Save any existing key maps
function M.save_existing()
	for _, entry in ipairs(entire_key_maps) do
		local key_spec = entry[1]
		local name = entry[2]
		local reg = function_registry[name]
		if reg then
			local modes = wrap_in_table(reg.mode)
			local keys = wrap_in_table(key_spec)
			if is_default_allowed(name) then
				for _, mode in ipairs(modes) do
					for _, key in ipairs(keys) do
						save_existing_key_map(mode, key)
					end
				end
			end
		end
	end
end

-- Restore key maps
function M.restore_existing()
	for _, existing in ipairs(existing_key_maps) do
		vim.fn.mapset(existing[1], false, existing[2])
	end
	existing_key_maps = {}
end

-- Call func with virtualedit = onemore if mode is insert or replace
local function with_onemore(func)
	if not common.is_mode_insert_replace() then
		func()
		return
	end
	local ve = vim.wo.ve
	local cursor_pos = vim.fn.getcurpos()
	vim.wo.ve = "onemore"
	vim.fn.cursor({ cursor_pos[2], cursor_pos[3], cursor_pos[4], cursor_pos[5] })
	func()
	local cursor_pos = vim.fn.getcurpos()
	vim.wo.ve = ve
	vim.fn.cursor({ cursor_pos[2], cursor_pos[3], cursor_pos[4], cursor_pos[5] })
end

-- Function to execute a custom key map
local function custom_function(func)
	local register = vim.v.register
	local count = vim.v.count
	with_onemore(function()
		func(register, count)
	end)
	if common.is_mode("v") then
		virtual_cursors.visual_mode(function(vc)
			func(register, count)
		end)
	else
		virtual_cursors.edit_with_cursor(function(vc)
			func(register, count)
		end)
	end
end

local function custom_function_with_motion(func)
	local register = vim.v.register
	local count = vim.v.count
	local motion_cmd = input.get_motion_cmd()
	if motion_cmd == nil then
		return
	end
	with_onemore(function()
		func(register, count, motion_cmd)
	end)
	if common.is_mode("v") then
		virtual_cursors.visual_mode(function(vc)
			func(register, count, motion_cmd)
		end)
	else
		virtual_cursors.edit_with_cursor(function(vc)
			func(register, count, motion_cmd)
		end)
	end
end

local function custom_function_with_char(func)
	local register = vim.v.register
	local count = vim.v.count
	local char = input.get_char()
	if char == nil then
		return
	end
	with_onemore(function()
		func(register, count, char)
	end)
	if common.is_mode("v") then
		virtual_cursors.visual_mode(function(vc)
			func(register, count, char)
		end)
	else
		virtual_cursors.edit_with_cursor(function(vc)
			func(register, count, char)
		end)
	end
end

local function custom_function_with_motion_then_char(func)
	local register = vim.v.register
	local count = vim.v.count
	local motion_cmd = input.get_motion_cmd()
	if motion_cmd == nil then
		return
	end
	local char = input.get_char()
	if char == nil then
		return
	end
	with_onemore(function()
		func(register, count, motion_cmd, char)
	end)
	if common.is_mode("v") then
		virtual_cursors.visual_mode(function(vc)
			func(register, count, motion_cmd, char)
		end)
	else
		virtual_cursors.edit_with_cursor(function(vc)
			func(register, count, motion_cmd, char)
		end)
	end
end

-- Resolve function spec to actual function
local function resolve_func(spec)
	if type(spec) == "function" then
		return spec
	end
	local reg = function_registry[spec]
	return reg and reg.fn or nil
end

-- Set any custom key maps
function M.set_custom()
	for _, custom_key_map in ipairs(custom_key_maps) do
		local custom_modes = wrap_in_table(custom_key_map[1])
		local custom_keys = wrap_in_table(custom_key_map[2])
		local func = resolve_func(custom_key_map[3])
		if func then
			local wrapped = function()
				custom_function(func)
			end
			if #custom_key_map >= 4 then
				local opt = custom_key_map[4]
				if opt == "m" then
					wrapped = function()
						custom_function_with_motion(func)
					end
				elseif opt == "c" then
					wrapped = function()
						custom_function_with_char(func)
					end
				elseif opt == "mc" then
					wrapped = function()
						custom_function_with_motion_then_char(func)
					end
				end
			end
			for _, m in ipairs(custom_modes) do
				for _, k in ipairs(custom_keys) do
					vim.keymap.set(m, k, wrapped, { buffer = 0 })
				end
			end
		end
	end
end

-- Print merged key maps for debugging
function M.print()
	local lines = {}
	local function add(fmt, ...)
		table.insert(lines, string.format(fmt, ...))
	end
	add("%-28s %-12s %-20s %s", "Name", "Mode", "Keys", "Source")
	add("%s", string.rep("-", 75))
	for _, entry in ipairs(entire_key_maps) do
		local key_spec = entry[1]
		local name = entry[2]
		local reg = function_registry[name]
		if reg then
			local modes = wrap_in_table(reg.mode)
			local keys = wrap_in_table(key_spec)
			local mode_str = table.concat(modes, ",")
			local key_str = table.concat(keys, " ")
			local source = is_default_allowed(name) and "[def]" or "[cust]"
			add("%-28s %-12s %-20s %s", name, mode_str, key_str, source)
		else
			add("%-28s %-12s %-20s %s", name, "?", "?", "[missing]")
		end
	end
	for _, custom in ipairs(custom_key_maps) do
		local modes = wrap_in_table(custom[1])
		local keys = wrap_in_table(custom[2])
		local func_spec = custom[3]
		local mode_str = table.concat(modes, ",")
		local key_str = table.concat(keys, " ")
		local name_str = type(func_spec) == "string" and func_spec or "<fn>"
		add("%-28s %-12s %-20s %s", name_str, mode_str, key_str, "[custom]")
	end
	vim.print(table.concat(lines, "\n"))
end

-- Set key maps used by this plug-in
function M.set()
	for _, entry in ipairs(entire_key_maps) do
		local key_spec = entry[1]
		local name = entry[2]
		local reg = function_registry[name]
		if reg then
			local func = reg.fn
			local modes = wrap_in_table(reg.mode)
			local keys = wrap_in_table(key_spec)
			if is_default_allowed(name) then
				for _, mode in ipairs(modes) do
					for _, key in ipairs(keys) do
						vim.keymap.set(mode, key, func, { buffer = 0 })
					end
				end
			end
		end
	end
	M.set_custom()
end

-- Delete key maps used by this plug-in
function M.delete()
	for _, entry in ipairs(entire_key_maps) do
		local key_spec = entry[1]
		local name = entry[2]
		local reg = function_registry[name]
		if reg then
			local modes = wrap_in_table(reg.mode)
			local keys = wrap_in_table(key_spec)
			if is_default_allowed(name) then
				for _, mode in ipairs(modes) do
					for _, key in ipairs(keys) do
						pcall(vim.keymap.del, mode, key, { buffer = 0 })
					end
				end
			end
		end
	end
	for _, custom in ipairs(custom_key_maps) do
		local modes = wrap_in_table(custom[1])
		local keys = wrap_in_table(custom[2])
		if custom[3] then
			for _, m in ipairs(modes) do
				for _, k in ipairs(keys) do
					pcall(vim.keymap.del, m, k, { buffer = 0 })
				end
			end
		end
	end
end

return M
