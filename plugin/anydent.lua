local anydent = require('anydent')

anydent.register_preset('lua', require('anydent.presets.lua')())

vim.g.anydent = {
  indentexpr = function()
    return anydent.indentexpr()
  end
}
