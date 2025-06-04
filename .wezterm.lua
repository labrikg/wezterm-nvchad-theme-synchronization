-- ~/.wezterm.lua
local wezterm = require 'wezterm'
local config = {}

local home_directory = os.getenv("HOME")
wezterm.log_info("Value of os.getenv('HOME'): " .. (home_directory or "nil"))

local nvchad_theme_file_path

if home_directory and type(home_directory) == "string" then
  nvchad_theme_file_path = home_directory .. "/.cache/current_nvchad_theme_for_wezterm"
  wezterm.log_info("Constructed nvchad_theme_file_path: '" .. nvchad_theme_file_path .. "'")
else
  wezterm.log_error("HOME environment variable is nil or not a string. Cannot construct path to theme file. HOME was: " .. tostring(home_directory))
  -- Set a dummy path to allow script to load without crashing on concatenation.
  nvchad_theme_file_path = "/tmp/WEZTERM_THEME_SYNC_PATH_ERROR_HOME_NIL"
end

-- Function to read the theme name from the file
local function get_theme_from_file(file_path_arg)
  wezterm.log_info("get_theme_from_file called with file_path_arg: '" .. (file_path_arg or "nil") .. "'")

  if not file_path_arg or type(file_path_arg) ~= "string" then
    wezterm.log_error("get_theme_from_file received an invalid file_path_arg (nil or not a string): " .. tostring(file_path_arg))
    return nil
  end

  local file, err = io.open(file_path_arg, "r")
  if not file then
    -- Log an error if the file can't be opened, but only if it's not the dummy error path
    if file_path_arg ~= "/tmp/WEZTERM_THEME_SYNC_PATH_ERROR_HOME_NIL" then
        wezterm.log_warn("Could not open theme file '" .. file_path_arg .. "' for reading. Error: " .. (err or "unknown error"))
    end
    return nil
  end

  local theme_name = file:read("*a") -- Read the whole file
  file:close()

  if theme_name then
    theme_name = theme_name:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
    if #theme_name > 0 then
      return theme_name
    end
  end
  wezterm.log_warn("Theme file '" .. file_path_arg .. "' was empty or contained only whitespace.")
  return nil
end

-- Function to apply the theme to all WezTerm windows
local function apply_theme_to_all_windows(theme_name)
  if not theme_name then
    wezterm.log_warn("apply_theme_to_all_windows called with nil or empty theme_name")
    return
  end

  wezterm.log_info("Attempting to apply WezTerm theme: '" .. theme_name .. "' to all windows.")
  local applied_to_any = false
  for _, window in ipairs(wezterm.gui.enumerate_windows()) do
    local success = window:set_config_overrides({ color_scheme = theme_name })
    if success then
      wezterm.log_info("Successfully applied theme '" .. theme_name .. "' to window ID " .. tostring(window:window_id()))
      applied_to_any = true
    else
      wezterm.log_error("Failed to apply theme '" .. theme_name .. "' to window ID " .. tostring(window:window_id()) .. ". Is '" .. theme_name .. "' a valid WezTerm color scheme? Check with `wezterm ls-color-schemes`.")
    end
  end
  if not applied_to_any then
    wezterm.log_warn("Theme '" .. theme_name .. "' was not applied to any windows. Perhaps no windows were open or the theme name is invalid across the board.")
  end
end

-- Set the initial color scheme when WezTerm starts
wezterm.log_info("Setting initial color scheme. nvchad_theme_file_path is: '" .. (nvchad_theme_file_path or "nil") .. "'")
local initial_theme_name = get_theme_from_file(nvchad_theme_file_path)
if initial_theme_name then
  config.color_scheme = initial_theme_name
  wezterm.log_info("Initial WezTerm theme set to: '" .. initial_theme_name .. "' from file.")
else
  config.color_scheme = 'Builtin Dark'
  if nvchad_theme_file_path ~= "/tmp/WEZTERM_THEME_SYNC_PATH_ERROR_HOME_NIL" then
    wezterm.log_warn("NvChad theme file ('" .. nvchad_theme_file_path .. "') not found or empty at startup. Using default WezTerm theme: '" .. config.color_scheme .. "'")
  else
    wezterm.log_warn("Cannot read NvChad theme file due to HOME env issue. Using default WezTerm theme: '" .. config.color_scheme .. "'")
  end
end

-- Other WezTerm configurations below this line


config.font_size = 19
config.enable_tab_bar = false
config.window_decorations = "RESIZE"

config.window_background_opacity = 0.9
config.macos_window_background_blur = 8

return config
