-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Preferences
-- Split Vertically
config.keys = {
  -- This will create a new split and run your default program inside it
  {
    key = '"',
    mods = 'CTRL|SHIFT|ALT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
}

-- Split Horizontally
config.keys = {
  -- This will create a new split and run your default program inside it
  {
    key = '%',
    mods = 'CTRL|SHIFT|ALT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
}

-- Font & Color Scheme
config.color_scheme = 'Gruvbox Dark (Gogh)'
config.font = wezterm.font('FiraCode Nerd Font', { weight = 'Bold', italic = false })
config.font_size = 9.0

-- and finally, return the configuration to wezterm
return config