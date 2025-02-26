---@return anydent.Preset
return function()
  local anydent = require('anydent')
  return {
    priority = -1,
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
