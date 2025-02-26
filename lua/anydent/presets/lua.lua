---@return anydent.Preset
return function()
  local anydent = require('anydent')
  return {
    indent_specs = {
      anydent.spec.pattern({
        prev = { [[\<do\>]], '$' },
      }),
      anydent.spec.pattern({
        prev = { [[\<then\>]], '$' },
      }),
      anydent.spec.pattern({
        prev = { [[\<else\>]], '$' },
      }),
      anydent.spec.pattern({
        prev = { [[\<elseif\>]], '$' },
      }),
      anydent.spec.pattern({
        prev = { [[\<repeat\>]], '$' },
      }),
      anydent.spec.pattern({
        prev = { [[\<function\>]], '(', [=[[^)]*]=], ')', '$' }
      }),
      anydent.spec.pattern({
        prev = { [[\<function\>]], [=[\%(\w\|\.\)*]=], '(', [=[[^)]*]=], ')', '$' }
      }),
    },
    dedent_specs = {
      anydent.spec.pattern({
        curr = { [[\<end\>]], '$' },
      }),
      anydent.spec.pattern({
        curr = { [[\<until\>]], '$' },
      }),
    },
  }
end
