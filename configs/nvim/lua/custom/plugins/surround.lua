local surround = require 'mini.surround'
local mappings = surround.config.mappings

local function delete_mapping(mode, lhs)
  if lhs ~= '' then
    pcall(vim.keymap.del, mode, lhs)
  end
end

local function delete_action_mappings(action, modes)
  local lhs = mappings[action]
  for _, mode in ipairs(modes) do
    delete_mapping(mode, lhs)
    delete_mapping(mode, lhs ~= '' and lhs .. mappings.suffix_last or '')
    delete_mapping(mode, lhs ~= '' and lhs .. mappings.suffix_next or '')
  end
end

delete_action_mappings('add', { 'n', 'x' })
delete_action_mappings('delete', { 'n' })
delete_action_mappings('replace', { 'n' })
delete_action_mappings('find', { 'n', 'x', 'o' })
delete_action_mappings('find_left', { 'n', 'x', 'o' })
delete_action_mappings('highlight', { 'n' })

for _, mode in ipairs { 'n', 'x', 'o' } do
  delete_mapping(mode, 's')
end

surround.setup {
  mappings = {
    add = 'ys',
    delete = 'ds',
    find = '',
    find_left = '',
    highlight = '',
    replace = 'cs',
    suffix_last = '',
    suffix_next = '',
  },
}
