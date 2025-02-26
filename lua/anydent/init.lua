---@class anydent.Context
---@field prev anydent.RowContext
---@field curr anydent.RowContext
---@field next anydent.RowContext

---@class anydent.RowContext
---@field row integer 1-indexed row number
---@field line string line content
---@field indent_count integer indent level

---@class anydent.DedentSpec
---@field priority? integer
---@field resolve fun(ctx: anydent.Context): boolean

---@class anydent.IndentSpec
---@field priority? integer
---@field resolve fun(ctx: anydent.Context): boolean

---@class anydent.ManualSpec
---@field priority? integer
---@field resolve fun(ctx: anydent.Context): boolean
---@field detect fun(ctx: anydent.Context): integer

---@class anydent.Preset
---@field priority? integer
---@field dedent_specs anydent.DedentSpec[]
---@field indent_specs anydent.IndentSpec[]
---@field manual_specs anydent.ManualSpec[]

---@class anydent.Config
---@field filetype table<string, anydent.Preset[]>

local anydent = {}

local P = {
  config = {
    filetype = {
      ['*'] = {
        {
          dedent_specs = {},
          indent_specs = {},
          manual_specs = {},
        }
      }
    }
  },
}

---Get the indent string of the current buffer.
---@return string
local function get_one_indent()
  local shiftwidth = vim.bo.shiftwidth or 0
  local tabstop = vim.bo.tabstop or 0
  return (' '):rep(shiftwidth ~= 0 and shiftwidth or tabstop)
end

---Get the indent count of the given text.
---@param text string
---@return integer
local function get_indent_count(text)
  local one_indent = get_one_indent()
  local indent_text = text:match('^(%s*)'):gsub('\t', one_indent)
  return math.floor(#indent_text / #one_indent) * #one_indent
end

---Get row context.
---@param row integer
---@return anydent.RowContext
local function get_row_context(row)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
  return {
    row = row,
    line = line,
    indent_count = get_indent_count(line),
  }
end

local get_regex --[[@type fun(pattern: string|string[]): vim.regex]]
do
  local cache = {}
  get_regex = function(pattern)
    if not cache[pattern] then
      if type(pattern) == 'table' then
        pattern = table.concat(pattern, '\\s*')
      end
      cache[pattern] = vim.regex(pattern)
    end
    return cache[pattern]
  end
end

---Anydent spec definer.
anydent.spec = {}

---Define a pattern spec.
---@param option { prev?: string|string[], curr?: string|string[], next?: string|string[] }
function anydent.spec.pattern(option)
  if not option.prev and not option.curr and not option.next then
    error('at least one of prev, curr, next must be specified')
  end

  return {
    resolve = function(row_ctx)
      if option.prev then
        if not get_regex(option.prev):match_str(row_ctx.prev.line) then
          return false
        end
      end
      if option.curr then
        if not get_regex(option.curr):match_str(row_ctx.curr.line) then
          return false
        end
      end
      if option.next then
        if not get_regex(option.next):match_str(row_ctx.next.line) then
          return false
        end
      end
      return true
    end
  }
end

---Register a preset.
---The '*' filetype for all buffers.
---@param filetype string
---@param preset anydent.Preset
function anydent.register_preset(filetype, preset)
  if not P.config.filetype[filetype] then
    P.config.filetype[filetype] = {}
  end
  table.insert(P.config.filetype[filetype], preset)
end

---vim.b.indentexpr function.
---@return integer
function anydent.indentexpr()
  vim.print('indentexpr')
  local ctx = {
    prev = get_row_context(math.max(1, vim.v.lnum - 1)),
    curr = get_row_context(vim.v.lnum),
    next = get_row_context(math.min(vim.v.lnum + 1, vim.fn.line('$'))),
    one_indent = get_one_indent(),
    shiftwidth = vim.fn.shiftwidth()
  }

  local presets = {}
  for _, preset in ipairs(P.config.filetype[vim.bo.filetype] or {}) do
    table.insert(presets, preset)
  end
  for _, preset in ipairs(P.config.filetype['*'] or {}) do
    table.insert(presets, preset)
  end
  table.sort(presets, function(a, b)
    return (a.priority or 0) > (b.priority or 0)
  end)
  for _, preset in ipairs(presets) do
    -- manual.
    for _, spec in ipairs(preset.manual_specs or {}) do
      if spec.resolve(ctx) then
        return spec.detect(ctx)
      end
    end
    -- dedent.
    table.sort(preset.dedent_specs or {}, function(a, b)
      return (a.priority or 0) > (b.priority or 0)
    end)
    for _, spec in ipairs(preset.dedent_specs or {}) do
      if spec.resolve(ctx) then
        return ctx.prev.indent_count - ctx.shiftwidth
      end
    end
    -- indent.
    table.sort(preset.indent_specs or {}, function(a, b)
      return (a.priority or 0) > (b.priority or 0)
    end)
    for _, spec in ipairs(preset.indent_specs or {}) do
      if spec.resolve(ctx) then
        return ctx.prev.indent_count + ctx.shiftwidth
      end
    end
  end
  vim.print('prev')
  return ctx.prev.indent_count
end

return anydent
