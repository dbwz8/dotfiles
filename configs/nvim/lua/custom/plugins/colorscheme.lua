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
    colors.bg_statusline = '#284b32'
    colors.bg_statusline_active = '#315b3d'
  end,
  on_highlights = function(highlights, colors)
    highlights.Normal = { bg = colors.bg }
    highlights.NormalNC = { bg = colors.bg }
    highlights.NormalFloat = { bg = colors.bg_float }
    highlights.SignColumn = { bg = colors.bg }
    highlights.EndOfBuffer = { bg = colors.bg }
    highlights.FoldColumn = { bg = colors.bg }
    highlights.MiniStatuslineDevinfo = { fg = colors.fg, bg = colors.bg_statusline_active }
    highlights.MiniStatuslineFilename = { fg = colors.fg, bg = colors.bg_statusline }
    highlights.MiniStatuslineFileinfo = { fg = colors.fg, bg = colors.bg_statusline_active }
    highlights.MiniStatuslineInactive = { fg = colors.green, bg = colors.bg_statusline }
    highlights.MiniStatuslineModeNormal = { fg = colors.black, bg = colors.green, bold = true }
  end,
}

vim.cmd.colorscheme 'tokyonight-night'
