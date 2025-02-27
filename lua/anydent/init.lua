---@class anydent.Context
---@field prev anydent.RowContext
---@field curr anydent.RowContext
---@field next anydent.RowContext
---@field one_indent string
---@field shiftwidth integer

---@class anydent.RowContext
---@field row integer 1-indexed row number
---@field line string line content
---@field indent_count integer indent level

---@class anydent.Spec
---@field name string
---@field priority? integer
---@field resolve fun(ctx: anydent.Context): boolean

---@class anydent.ManualSpec
---@field name string
---@field priority? integer
---@field resolve fun(ctx: anydent.Context): boolean
---@field detect fun(ctx: anydent.Context): integer

---@class anydent.Preset
---@field name string
---@field priority? integer
---@field indentkeys? string[]
---@field dedent_specs? anydent.Spec[]
---@field indent_specs? anydent.Spec[]
---@field manual_specs? anydent.ManualSpec[]

---@class anydent.Config
---@field filetype table<string, anydent.Preset[]>

local anydent = {}

local P = {
  config = {
    filetype = {}
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
---NOTE: always count as <Space> count (the \t will be converted as one indent).
---@param text string
---@return integer
local function get_indent_count(text)
  return #(text:match('^(%s*)'):gsub('\t', get_one_indent()) or '')
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

---Get prev non-blank row.
---@param row integer
---@return integer
local function get_prev_nonblank_row(row)
  for i = row - 1, 1, -1 do
    local text = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ''
    if text:gsub('%s', '') ~= '' then
      return i
    end
  end
  return 1
end

---Get next non-blank row.
---@param row integer
---@return integer
local function get_next_nonblank_row(row)
  for i = row + 1, vim.fn.line('$') do
    local text = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ''
    if text:gsub('%s', '') ~= '' then
      return i
    end
  end
  return vim.fn.line('$')
end

---Debug print.
---@vararg any
local function debug_print(...)
  if vim.g.anydent_debug then
    vim.print(...)
  end
end

local get_regex
do
  local cache = {}

  ---Get cached regex object.
  ---@param pattern string|string[]
  ---@return vim.regex
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
---@return anydent.Spec
function anydent.spec.pattern(option)
  if not option.prev and not option.curr and not option.next then
    error('at least one of prev, curr, next must be specified')
  end

  ---@type anydent.Spec
  return {
    name = ('pattern: prev=`%s`, curr=`%s`, next=`%s`'):format(option.prev or '', option.curr or '', option.next or ''),
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

---Get indent count by row.
---@param row integer
---@return integer
function anydent.get_indent_count(row)
  return get_row_context(row).indent_count
end

---Register a preset.
---The '*' filetype for all buffers.
---@param filetype string
---@param presets anydent.Preset[]
function anydent.register_presets(filetype, presets)
  if not P.config.filetype[filetype] then
    P.config.filetype[filetype] = {}
  end
  for _, preset in ipairs(presets) do
    table.insert(P.config.filetype[filetype], preset)
  end
end

---Get the presets of the buffer.
---@param buf integer
---@return anydent.Preset[]
function anydent.get_presets(buf)
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf

  local filetype = vim.bo[buf].filetype
  local presets = {}
  if P.config.filetype[filetype] then
    for _, preset in ipairs(P.config.filetype[filetype] or {}) do
      table.insert(presets, preset)
    end
  else
    for _, preset in ipairs(P.config.filetype['*'] or {}) do
      table.insert(presets, preset)
    end
  end
  table.sort(presets, function(a, b)
    return (a.priority or 0) > (b.priority or 0)
  end)
  return presets
end

---vim.b.indentexpr function.
---@return integer
function anydent.indentexpr()
  ---@type anydent.Context
  local ctx = {
    prev = get_row_context(get_prev_nonblank_row(vim.v.lnum)),
    curr = get_row_context(vim.v.lnum),
    next = get_row_context(get_next_nonblank_row(vim.v.lnum)),
    one_indent = get_one_indent(),
    shiftwidth = vim.fn.shiftwidth()
  }

  local presets = anydent.get_presets(0)

  debug_print('>>> detection: ' .. ctx.curr.line)
  local prev_indent_count = ctx.prev.indent_count

  local dedented = false
  local indented = false
  for _, preset in ipairs(presets) do
    debug_print(('  preset: %s'):format(preset.name))
    -- manual.
    for _, spec in ipairs(preset.manual_specs or {}) do
      if spec.resolve(ctx) then
        return spec.detect(ctx)
      end
    end
    -- dedent.
    if dedented then
      table.sort(preset.dedent_specs or {}, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
      end)
      for _, spec in ipairs(preset.dedent_specs or {}) do
        if spec.resolve(ctx) then
          debug_print(('    dedent: [%s] %s'):format(preset.name, spec.name))
          prev_indent_count = prev_indent_count - ctx.shiftwidth
          dedented = true
        end
      end
    end
    -- indent.
    if not indented then
      table.sort(preset.indent_specs or {}, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
      end)
      for _, spec in ipairs(preset.indent_specs or {}) do
        if spec.resolve(ctx) then
          debug_print(('    indent: [%s] %s'):format(preset.name, spec.name))
          prev_indent_count = prev_indent_count + ctx.shiftwidth
          indented = true
        end
      end
    end
  end
  return prev_indent_count
end

---Attach anydent to the buffer.
function anydent.attach()
  local buf = vim.api.nvim_get_current_buf()
  -- indentexpr.
  do
    vim.b[buf].anydent = {
      indentexpr = anydent.indentexpr,
    }
    vim.bo[buf].indentexpr = 'b:anydent.indentexpr()'
  end

  -- indentkeys
  do
    local indentkeys_map = {} --[[@type table<string, boolean>]]
    for _, preset in ipairs(anydent.get_presets(0)) do
      for _, key in ipairs(preset.indentkeys or {}) do
        indentkeys_map[key] = true
      end
    end
    vim.bo[buf].indentkeys = vim.bo[buf].indentkeys .. ',' .. vim.iter(vim.tbl_keys(indentkeys_map)):map(function(key)
      return ('=%s'):format(vim.fn.escape(key, ', \t\\*'))
    end):join(',')
  end
end

return anydent
