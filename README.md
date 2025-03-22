# Markdown Mover

A Neovim plugin that automatically moves markdown files based on tags in their YAML frontmatter.

## Features

- Automatically organizes markdown files into directories based on frontmatter tags
- Only processes actual markdown files with YAML frontmatter
- Convenient keymapping for moving files
- Works only when tags match configured destinations
- Compatible with lazy.nvim
- Customizable configuration
- Ignore specific directories from being processed
- Default ignored directories for common development folders
- Supports paths relative to git repository root

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- In your lazy.nvim plugins file
return {
  {
    "hsteinshiromoto/markdown-mover.nvim", -- For GitHub hosted plugin
    -- or local plugin in your config
    -- dir = "~/path/to/markdown-mover.nvim",
    -- dev = true, -- For local development
    ft = "markdown",
    opts = {
      tag_field = "tags",
      tag_rules = {
        ["project"] = "docs/projects/",
        ["draft"] = "docs/drafts/",
        ["blog"] = "docs/blog/",
      },
      keymap = "<leader>mm",
    },
  }
}
```

### Local Development

For local development inside your Neovim config:

1. Create the directory structure:
   ```bash
   mkdir -p ~/.config/nvim/lua/markdown-mover
   ```

2. Copy the plugin code to this location:
   ```bash
   cp init.lua ~/.config/nvim/lua/markdown-mover/
   ```

3. Add the lazy.nvim configuration as shown above with `dev = true`

## Configuration

```lua
require('markdown-mover').setup({
  tag_field = "tags",    -- The name of the frontmatter field containing tags
  tag_rules = {
    ["project"] = "docs/projects/",  -- Relative to git root
    ["draft"] = "docs/drafts/",      -- Relative to git root
    ["blog"] = "docs/blog/",         -- Relative to git root
  },
  default_path = "docs/uncategorized/",  -- Default path if no matching tag (nil to disable)
  auto_move = false,     -- Move files automatically on save
  verbose = true,        -- Show notifications
  keymap = "<leader>mm", -- Keymap for manual moving (empty to disable)
  ignore_dirs = {        -- Directories to ignore (can be patterns)
    ".*/meta/.*",        -- Ignore meta directories
    ".*/logs/.*",        -- Ignore log directories
    ".*/src/.*",         -- Ignore source code directories
    ".*/notebooks/.*",   -- Ignore notebook directories
    "~/Documents/archive/.*",  -- Additional custom ignore patterns
  }
})
```

## Path Resolution

The plugin now supports paths relative to your git repository root:

- If a path starts with `~` or `/`, it's treated as an absolute path
- Otherwise, the path is resolved relative to your git repository root
- If you're not in a git repository, the current directory is used as the root

Example path configurations:
```lua
tag_rules = {
  ["draft"] = "docs/drafts/",           -- Relative to git root
  ["archive"] = "~/Documents/archive/",  -- Absolute path
  ["temp"] = "/tmp/notes/"              -- Absolute path
}
```

## Usage

### Commands

- `:MarkdownMove` - Manually move the current file based on its frontmatter tags
- `:TestFrontmatter` - Test frontmatter parsing and display the results

### Keymap

- Default: `<leader>mm` - Move the current markdown file based on its tags

### Example File

```markdown
---
title: My Document
tags: [draft, blog]
date: 2025-03-20
---

# My Document

This is my test document.
```

If this file has the tag `draft` and you've configured a mapping for that tag, pressing `<leader>mm` will move it to the designated folder.

## Notes

- The plugin only moves files if they have tags that match your configured tag rules
- If a file has multiple matching tags, the first matching tag is used
- The file is only moved if it's a valid markdown file with proper YAML frontmatter
- By default, the plugin ignores files in directories containing: meta, logs, src, and notebooks
- You can override the default ignored directories by providing your own `ignore_dirs` configuration
- Paths in tag rules and default_path can be relative to git root or absolute paths
