local anydent = require('anydent')

anydent.register_presets('*', {
  require('anydent.presets.doc-comment')(),
  require('anydent.presets.common')(),
})
anydent.register_presets('lua', {
  require('anydent.presets.common')(),
  require('anydent.presets.lua')(),
})

