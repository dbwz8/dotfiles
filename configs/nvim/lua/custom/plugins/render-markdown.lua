vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  html = {
    comment = {
      conceal = false,
    },
  },
}
