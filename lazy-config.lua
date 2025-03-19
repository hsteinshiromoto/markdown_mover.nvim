-- File: ~/.config/nvim/lua/plugins/markdown-mover.lua

return {
  -- Define the plugin
  {
    -- Local plugin (for a directory in your ~/.config/nvim/lua/)
    "markdown-mover",
    
    -- Set plugin behavior
    dev = true,  -- Mark as a dev plugin (local in config)
    lazy = true, -- Load only when needed
    
    -- Specify loading conditions
    ft = "markdown", -- Only load for markdown files
    
    -- Configure the plugin
    opts = {
      tag_field = "tags",
      tag_rules = {
        ["project"] = "~/Documents/projects/",
        ["draft"] = "~/Documents/drafts/",
        ["blog"] = "~/Documents/blog/",
      },
      default_path = nil,   -- Set to nil to disable default path
      auto_move = false,    -- Set to true to enable auto-move on save
      verbose = true,
      keymap = "<leader>mm" -- Set your preferred keymap
    },
    
    -- This is executed when the plugin loads
    config = function(_, opts)
      require("markdown-mover").setup(opts)
    end,
  }
}
