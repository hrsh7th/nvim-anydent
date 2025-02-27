# nvim-anydent

`nvim-anydent` is a Neovim plugin that provides automatic indentation based on simple heuristics.

## Usage
```lua
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    if not vim.tbl_contains({ 'html', 'yaml', 'markdown'  }, vim.bo.filetype) then
      require('anydent').attach()
    end
  end
})
```

## How It Works

`nvim-anydent` determines indentation based on:

- **Indent Patterns:** If a line matches a predefined pattern indicating an increase in indentation (e.g., ending with `{` in C-style languages), the next line will be indented.
- **Dedent Patterns:** If a line matches a pattern signaling a decrease in indentation (e.g., starting with `}`), that line will be dedented.
- **Manual Patterns:** Customizable rules to handle special cases like doc comments.
- **Indentkeys:** A list of words that trigger automatic indentation when typed at the end of a line.

Based on the author's past experience, this approach worked correctly in most cases for languages with C-style syntax.

## Limitations

- `nvim-anydent` does not attempt to be a full-fledged indentation engine.
- It may not handle deeply nested or highly structured languages perfectly.
- It prioritizes consistency over strict correctness.

If you need a 100% accurate indentation system, language-specific tools or Treesitter-based solutions may be better suited. However, if you prefer an **always-reasonable** indentation solution, `nvim-anydent` is for you.

## Status

works basically

built-in presets.
  - common
  - doc-comment
  - lua

