---@mod key-menu.keys Key processing and mapping logic
local utils = require("key-menu.utils")

local M = {}

---Peel off the next keystroke of a 'lhs'.
---For example, peel('abc') => 'a', 'bc',
---             peel('<space>foo') => '<space>', 'foo'
---@param lhs string The mapping lhs string.
---@return string # The first keystroke.
---@return string # The rest of the string.
function M.peel(lhs)
	if lhs:sub(1, 1) == "<" then
		local last = 2
		while last <= #lhs and lhs:sub(last, last) ~= ">" do
			last = last + 1
		end
		-- If we didn't find a closing '>', treat as single char '<'
		if last > #lhs then
			return lhs:sub(1, 1), lhs:sub(2, -1)
		end
		return lhs:sub(1, last), lhs:sub(last + 1, -1)
	end
	return lhs:sub(1, 1), lhs:sub(2, -1)
end

---Peel off the next keystroke after a prefix.
---@param prefix string
---@param lhs string
---@return string # The next keystroke.
---@return string # The rest of the string.
function M.peel_after(prefix, lhs)
	if lhs:sub(1, #prefix) ~= prefix then
		error('Prefix "' .. prefix .. '" does not match start of "' .. lhs .. '"')
	end
	return M.peel(lhs:sub(#prefix + 1, -1))
end

---Split a prefix string into individual keystrokes.
---@param prefix string
---@return string[] # List of keystrokes.
function M.get_keystrokes(prefix)
	local result = {}
	while #prefix ~= 0 do
		local keystroke
		keystroke, prefix = M.peel(prefix)
		table.insert(result, keystroke)
	end
	return result
end

---Normalize a keymap list (deep copy).
---@param keymap table[]
---@return table[]
function M.normalize_keymap(keymap)
	return vim.deepcopy(keymap)
end

---Shadow old mappings with new ones.
---@param old_mappings table[]
---@param new_mappings table[]
---@return table[] # The combined list.
function M.shadow(old_mappings, new_mappings)
	local new_lhss = {}
	for _, m in ipairs(new_mappings) do
		new_lhss[m.lhs] = true
	end
	local result = vim.deepcopy(old_mappings)
	result = vim.tbl_filter(function(m)
		return not new_lhss[m.lhs]
	end, result)
	vim.list_extend(result, new_mappings, 1, #new_mappings)
	return result
end

---Check if a mapping is not a No-Op (empty rhs).
---@param mapping table
---@return boolean
function M.is_not_nop(mapping)
	return mapping.rhs ~= ""
end

---Check if a mapping is not hidden (via desc).
---@param mapping table
---@return boolean
function M.is_not_hidden(mapping)
	if mapping.desc == nil or mapping.desc == "" then
		return true
	end
	return string.upper(mapping.desc) ~= "HIDDEN"
end

---Check if a mapping starts with a prefix (and is strictly longer).
---@param prefix string
---@param mapping table
---@return boolean
function M.is_prefix_mapping_starting_with(prefix, mapping)
	return #prefix ~= #mapping.lhs and utils.starts_with(prefix, mapping.lhs)
end

---Filter mappings that start with a prefix.
---@param prefix string
---@param mappings table[]
---@return table[]
function M.prefix_mappings_starting_with(prefix, mappings)
	return vim.tbl_filter(function(m)
		return M.is_prefix_mapping_starting_with(prefix, m)
	end, mappings)
end

---Compute next keys and complete keys for a given prefix.
---@param prefix string
---@param mappings table[]
---@return table<string, table[]> # prefix_keys: keystroke -> list of mappings (continuations)
---@return table<string, table> # complete_keys: keystroke -> mapping (exact match)
function M.compute_keys(prefix, mappings)
	local complete_keys = {} -- keystroke-to-mapping
	local prefix_keys = {} -- keystroke-to-list-of-mappings
	for _, mapping in ipairs(mappings) do
		-- Get the key and description for this mapping.
		local key, tail = M.peel_after(prefix, mapping.lhs)
		local is_complete = (#tail == 0)
		if is_complete then
			complete_keys[key] = mapping
		else
			if not prefix_keys[key] then
				prefix_keys[key] = {}
			end
			table.insert(prefix_keys[key], mapping)
		end
	end
	return prefix_keys, complete_keys
end

return M
