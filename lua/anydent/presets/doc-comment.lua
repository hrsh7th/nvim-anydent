return function()
  local anydent = require('anydent')
  ---@type anydent.Preset
  return {
    name = 'doc-comment',
    priority = 1000,
    indentkeys = {
      '*'
    },
    manual_specs = {
      {
        name = 'doc-comment',
        resolve = function(ctx)
          for row = ctx.prev.row, 1, -1 do
            local text = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
            local doc_start = vim.regex([=[^\s*/\*\*$]=]):match_str(text) ~= nil
            local doc_middle = vim.regex([=[^\s*\*]=]):match_str(text) ~= nil
            if not doc_start and not doc_middle then
              break
            end
            if doc_start then
              return true
            end
          end
          return false
        end,
        detect = function(ctx)
          for row = ctx.prev.row, 1, -1 do
            local text = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
            local doc_start = vim.regex([=[^\s*/\*\*$]=]):match_str(text) ~= nil
            if doc_start then
              return anydent.get_indent_count(row) + 1
            end
          end
          return ctx.prev.indent_count
        end,
      }
    }
  }
end

