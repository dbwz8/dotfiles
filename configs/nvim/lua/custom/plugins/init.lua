local source = debug.getinfo(1, 'S').source:gsub('^@', '')
local plugins_dir = vim.fs.dirname(vim.uv.fs_realpath(source) or source)

for file_name, type in vim.fs.dir(plugins_dir, { follow = true }) do
  if (type == 'file' or type == 'link') and file_name:match '%.lua$' and file_name ~= 'init.lua' then
    local module = file_name:gsub('%.lua$', '')
    require('custom.plugins.' .. module)
  end
end
