return function()
  local anydent = require('anydent')
  ---@type anydent.Preset
  return {
    name = 'common',
    priority = -1,
    indentkeys = {
      '}',
      ']',
      '>',
      ')',
    },
    indent_specs = {
      anydent.spec.pattern({ prev = { [=[\V{\m]=], '$' } }),
      anydent.spec.pattern({ prev = { [=[\V[\m]=], '$' } }),
      anydent.spec.pattern({ prev = { [=[\V<\m]=], '$' } }),
      anydent.spec.pattern({ prev = { [=[\V(\m]=], '$' } }),
    },
    dedent_specs = {
      anydent.spec.pattern({ curr = { '^', [=[\V}\m]=], ',\\?' } }),
      anydent.spec.pattern({ curr = { '^', [=[\V]\m]=], ',\\?' } }),
      anydent.spec.pattern({ curr = { '^', [=[\V>\m]=], ',\\?' } }),
      anydent.spec.pattern({ curr = { '^', [=[\V)\m]=], ',\\?' } }),
    },
  }
end
