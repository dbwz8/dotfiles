vim.pack.add { 'https://github.com/akinsho/toggleterm.nvim' }

require('toggleterm').setup {
  direction = 'float',
  open_mapping = [[<c-\>]],
  shade_terminals = true,
  float_opts = {
    border = 'curved',
  },
}

vim.keymap.set('n', '<leader>tt', '<cmd>ToggleTerm<CR>', { desc = '[T]oggle [T]erminal' })
