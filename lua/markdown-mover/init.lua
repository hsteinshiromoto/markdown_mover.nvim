-- File: ~/.config/nvim/lua/markdown-mover/init.lua

-- Main module table
local M = {}

-- Private storage for the configuration (not directly accessible)
local config = {
  tag_field = "tags",  -- The field name in frontmatter containing tags
  tag_rules = {
    -- Example: ["draft"] = "~/Documents/drafts/"
  },
  default_path = nil,  -- Default destination if no tag matches
  auto_move = false,   -- Whether to move automatically on save
  verbose = true,      -- Show notifications
  keymap = "<leader>mm", -- Default keymap for moving markdown files
  ignore_dirs = {      -- Default directories to ignore
    ".*/meta/.*",      -- Ignore meta directories
    ".*/logs/.*",      -- Ignore log directories
    ".*/src/.*",       -- Ignore source code directories
    ".*/notebooks/.*", -- Ignore notebook directories
  }
}

-- Functions
local function parse_yaml_frontmatter()
  local start_line = -1
  local end_line = -1
  
  -- Find YAML frontmatter boundaries (lines with ---)
  for i = 1, 20 do  -- Check first 20 lines
    local line = vim.fn.getline(i)
    if i == 1 and line == "---" then
      start_line = i
    elseif start_line ~= -1 and line == "---" then
      end_line = i
      break
    end
  end
  
  if start_line == -1 or end_line == -1 then
    return nil
  end
  
  -- Extract YAML content
  local yaml_lines = {}
  for i = start_line + 1, end_line - 1 do
    table.insert(yaml_lines, vim.fn.getline(i))
  end
  
  -- Simple YAML parsing (for advanced parsing, consider using a proper YAML parser)
  local frontmatter = {}
  for _, line in ipairs(yaml_lines) do
    local key, value = line:match("^%s*([%w_-]+)%s*:%s*(.+)%s*$")
    if key and value then
      -- Handle array values (comma-separated)
      if value:match("%[.*%]") then
        local items = {}
        for item in value:gsub("%[", ""):gsub("%]", ""):gmatch("[^,]+") do
          table.insert(items, item:match("^%s*(.-)%s*$"))
        end
        frontmatter[key] = items
      -- Handle quoted strings
      elseif value:match('^".*"$') or value:match("^'.*'$") then
        frontmatter[key] = value:sub(2, -2)
      else
        frontmatter[key] = value
      end
    end
  end
  
  return frontmatter
end

local function is_in_ignored_dir(filepath)
  local normalized_path = vim.fn.fnamemodify(filepath, ":p")
  for _, pattern in ipairs(config.ignore_dirs) do
    if normalized_path:match(pattern) then
      return true
    end
  end
  return false
end

local function process_markdown_file()
  local current_file = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype
  
  -- Only process markdown files
  if not (current_file:match("%.md$") and filetype == "markdown") then
    if config.verbose then
      vim.notify("Not a markdown file, skipping", vim.log.levels.DEBUG)
    end
    return false
  end

  -- Check if file is in an ignored directory
  if is_in_ignored_dir(current_file) then
    if config.verbose then
      vim.notify("File is in an ignored directory, skipping", vim.log.levels.DEBUG)
    end
    return false
  end
  
  local frontmatter = parse_yaml_frontmatter()
  if not frontmatter then
    if config.verbose then
      vim.notify("No valid YAML frontmatter found", vim.log.levels.WARN)
    end
    return false
  end
  
  -- Check for tags
  local tags = frontmatter[config.tag_field]
  if not tags then
    if config.verbose then
      vim.notify("No tags field found in frontmatter", vim.log.levels.INFO)
    end
    return false
  end
  
  -- Convert to table if it's a string
  if type(tags) == "string" then
    tags = {tags}
  end
  
  -- Check each tag against our rules
  local tag_matched = false
  
  for _, tag in ipairs(tags) do
    tag = tag:match("^%s*(.-)%s*$")  -- Trim whitespace
    local destination = config.tag_rules[tag]
    if destination then
      tag_matched = true
      -- Ensure destination directory exists
      local dest_dir = vim.fn.fnamemodify(destination, ":p")
      if vim.fn.isdirectory(dest_dir) == 0 then
        vim.fn.mkdir(dest_dir, "p")
      end
      
      -- Create full destination path
      local filename = vim.fn.fnamemodify(current_file, ":t")
      local dest_file = dest_dir .. "/" .. filename
      
      -- Save the file first
      vim.cmd("write")
      
      -- Move the file
      local success, err = os.rename(current_file, dest_file)
      if success then
        if config.verbose then
          vim.notify(string.format("Moved file to %s based on tag '%s'", dest_file, tag), vim.log.levels.INFO)
        end
        
        -- Open the file in its new location
        vim.cmd("edit " .. dest_file)
        return true
      else
        vim.notify(string.format("Failed to move file: %s", err), vim.log.levels.ERROR)
        return false
      end
    end
  end
  
  -- If we have a default path and no specific rule matched
  if not tag_matched and config.default_path and config.default_path ~= "" then
    local dest_dir = vim.fn.fnamemodify(config.default_path, ":p")
    if vim.fn.isdirectory(dest_dir) == 0 then
      vim.fn.mkdir(dest_dir, "p")
    end
    
    local filename = vim.fn.fnamemodify(current_file, ":t")
    local dest_file = dest_dir .. "/" .. filename
    
    vim.cmd("write")
    
    local success, err = os.rename(current_file, dest_file)
    if success then
      if config.verbose then
        vim.notify(string.format("Moved file to default location %s", dest_file), vim.log.levels.INFO)
      end
      
      vim.cmd("edit " .. dest_file)
      return true
    else
      vim.notify(string.format("Failed to move file to default location: %s", err), vim.log.levels.ERROR)
      return false
    end
  end
  
  -- If no matching tag rule was found and no default path
  if not tag_matched then
    if config.verbose then
      vim.notify("No matching tag rule found for this file", vim.log.levels.INFO)
    end
    return false
  end
  
  return false
end

local function setup_keymaps()
  vim.keymap.set('n', config.keymap, function()
    if vim.bo.filetype == "markdown" then
      process_markdown_file()
    else
      if config.verbose then
        vim.notify("Current buffer is not a markdown file", vim.log.levels.WARN)
      end
    end
  end, { desc = "Move markdown file based on frontmatter tags" })
end

local function create_autocommands()
  local augroup = vim.api.nvim_create_augroup("MarkdownMover", { clear = true })
  
  if config.auto_move then
    -- Auto move on save
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = augroup,
      pattern = "*.md",
      callback = function()
        -- Double-check filetype
        if vim.bo.filetype == "markdown" then
          process_markdown_file()
        end
      end,
    })
  end
  
  -- Add a command to manually trigger the move, but only for markdown files
  vim.api.nvim_create_user_command("MarkdownMove", function()
    if vim.bo.filetype == "markdown" then
      local result = process_markdown_file()
      if not result and config.verbose then
        vim.notify("No action taken: file had no matching tags or tag rules", vim.log.levels.INFO)
      end
    else
      vim.notify("Current buffer is not a markdown file", vim.log.levels.WARN)
    end
  end, {})
  
  -- Add a command to test the frontmatter parsing
  vim.api.nvim_create_user_command("TestFrontmatter", function()
    if vim.bo.filetype ~= "markdown" then
      vim.notify("Current buffer is not a markdown file", vim.log.levels.WARN)
      return
    end
    
    local frontmatter = parse_yaml_frontmatter()
    if frontmatter then
      vim.notify("Frontmatter: " .. vim.inspect(frontmatter), vim.log.levels.INFO)
    else
      vim.notify("No frontmatter found", vim.log.levels.WARN)
    end
  end, {})
end

-- Public setup function
function M.setup(opts)
  -- Merge user config with defaults
  if opts then
    config = vim.tbl_deep_extend("force", config, opts)
  end
  
  -- Initialize the plugin
  create_autocommands()
  
  -- Set up keymaps if configured
  if config.keymap and config.keymap ~= "" then
    setup_keymaps()
  end
end

-- Return the module table
return M
