require('tokyonight').setup {
  style = 'night',
  transparent = false,
  on_colors = function(colors)
    colors.bg = '#000000'
    colors.bg_dark = '#000000'
    colors.bg_dark1 = '#000000'
    colors.bg_float = '#000000'
    colors.bg_popup = '#000000'
    colors.bg_sidebar = '#000000'
    colors.bg_statusline = '#000000'
  end,
  on_highlights = function(highlights, colors)
    highlights.Normal = { bg = colors.bg }
    highlights.NormalNC = { bg = colors.bg }
    highlights.NormalFloat = { bg = colors.bg_float }
    highlights.SignColumn = { bg = colors.bg }
    highlights.EndOfBuffer = { bg = colors.bg }
    highlights.FoldColumn = { bg = colors.bg }
  end,
}

vim.cmd.colorscheme 'tokyonight-night'
