-- ~/.config/nvim/lua/custom/wezterm_theme_sync.lua
local M = {}

local theme_file_path = os.getenv("HOME") .. "/.cache/current_nvchad_theme_for_wezterm"

-- IMPORTANT: Make sure these NvChad theme names on the LEFT
-- correctly map to WezTerm theme names on the RIGHT.
local theme_map = {
  -- ["NvChadThemeName"] = "WezTermThemeName",
  ["ayu_dark"] = "Ayu Dark (Gogh)", 
  ["ashes"] = "Ashes (dark) (terminal.sexy)",
  ["ayu_light"] = "ayu_light",
  ["carbonfox"] = "carbonfox",
  ["catppuccin"] = "Catppuccin Mocha",
  ["dracula-dark"] = "Dracula+",
  ["default-dark"] = "Default Dark (terminal.sexy)",
  ["default-light"] = "Default Light (terminal.sexy)",
  ["doomchad"] = "Doom Peacock",
  ["eldritch"] = "Eldritch",
  ["everblush"] = "Everblush",
  ["everforest"] = "Everforest Dark Hard (Gogh)",
  ["everforest_light"] = "Everforest Light Hard (Gogh)",
  ["flexoki"] = "flexoki-dark",
  ["flexoki-light"] = "flexoki-light",
  ["github_light"] = "Github Light",
  ["gruvbox"] = "Gruvbox Dark (Gogh)",
  ["gruvbox_light"] = "Gruvbox (Gogh)",
  ["horizon"] = "Horizon Dark (Gogh)",
  ["jellybeans"] = "Jellybeans",
  ["kanagawa-dragon"] = "Kanagawa Dragon (Gogh)",
  ["kanagawa"] = "Kanagawa (Gogh)",
  ["material-darker"] = "MaterialDarker",
  ["material-deep-ocean"] = "MaterialOcean",
  ["material-lighter"] = "Material Lighter (base16)",
  ["monekai"] = "Monokai Dark (Gogh)",
  ["neofusion"] = "Neon",
  ["nightfox"] = "nightfox",
  ["nord"] = "nord",
  ["oceanic-next"] = "Ocean (dark) (terminal.sexy)",
  ["oceanic-light"] = "Ocean (light) (terminal.sexy)",
  ["onedark"] = "OneDark (base16)",
  ["oxocarbon"] = "Oxocarbon Dark (Gogh)",
  ["palenight"] = "Palenight (Gogh)",
  ["poimandres"] = "Poimandres",
  ["rosepine-dawn"] = "rose-pine-dawn",
  ["rosepine"] = "rose-pine",
  ["seoul256_dark"] = "Seoul256 (Gogh)",
  ["seoul256_light"] = "Seoul256 Light (Gogh)",
  ["solarized_dark"] = "Solarized (dark) (terminal.sexy)",
  ["solarized_light"] = "Solarized (light) (terminal.sexy)",
  ["solarized_osaka"] = "Solarized Dark Higher Contrast",
  ["tokyonight"] = "Tokyo Night",
  ["tomorrow_night"] = "Tomorrow Night",
  ["vscode_dark"] = "Vs Code Dark+ (Gogh)",
  ["vscode_light"] = "Vs Code Light+ (Gogh)",
  ["wombat"] = "Wombat",
  ["zenburn"] = "Zenburn",  
}

-- Function to get theme from NvChad's static configuration (chadrc)
-- This is a fallback for initial theme detection if vim.g.base46_theme isn't set yet.
local function get_initial_theme_from_chadrc()
  local chadrc_theme = nil
  -- NvChad v2.5 loads chadrc.lua.
  -- This assumes your custom config is standard.
  -- Hide errors if custom.chadrc is not directly requirable or has issues.
  local success, chadrc_config = pcall(require, "custom.chadrc")

  if success and chadrc_config and chadrc_config.base46 and chadrc_config.base46.theme then
    chadrc_theme = chadrc_config.base46.theme
    vim.notify("Initial theme from chadrc.lua: " .. chadrc_theme, vim.log.levels.INFO, { title = "WezTerm Sync" })
  else
    -- As a deeper fallback, attempt to use NvChad's internal config loader if available   
    local util_paths = {"nvchad.core.utils", "core.utils"}
    for _, path in ipairs(util_paths) do
      local util_ok, utils = pcall(require, path)
      if util_ok and utils and utils.load_config then
        local config_ok, loaded_cfg = pcall(utils.load_config)
        if config_ok and loaded_cfg and loaded_cfg.base46 and loaded_cfg.base46.theme then
          chadrc_theme = loaded_cfg.base46.theme
          vim.notify("Initial theme from NvChad utils ("..path.."): " .. chadrc_theme, vim.log.levels.INFO, { title = "WezTerm Sync" })
          break
        end
      end
    end
    if not chadrc_theme then
      vim.notify("Could not determine initial theme from chadrc.lua or NvChad utils.", vim.log.levels.WARN, { title = "WezTerm Sync" })
    end
  end
  return chadrc_theme
end


function M.get_current_nvchad_theme_name(event_source)
  local current_theme = nil

  -- NvChad v2.5 often uses vim.g.base46_theme
  if vim.g.base46_theme and type(vim.g.base46_theme) == "string" and #vim.g.base46_theme > 0 then
    current_theme = vim.g.base46_theme
    vim.notify("Theme from vim.g.base46_theme: " .. current_theme .. " (Event: " .. event_source .. ")", vim.log.levels.INFO, { title = "WezTerm Sync" })
  -- Fallback for initial load if vim.g.base46_theme isn't populated yet
  elseif event_source == "VimEnter" then
    current_theme = get_initial_theme_from_chadrc()
  -- During/After a ColorScheme event, vim.v.colorscheme might be set
  elseif event_source == "ColorScheme" and vim.v.colorscheme and #vim.v.colorscheme > 0 then
    -- vim.v.colorscheme might be generic like "base46" or specific like "aylin"
    -- If it's generic, vim.g.base46_theme (checked above) is usually more accurate for the *flavor*.
    -- We only use this if vim.g.base46_theme wasn't found.
    current_theme = vim.v.colorscheme
    vim.notify("Theme from vim.v.colorscheme: " .. current_theme .. " (Event: " .. event_source .. ")", vim.log.levels.INFO, { title = "WezTerm Sync" })
  end

  if not current_theme and event_source ~= "VimEnter_SilentFail" then
     vim.notify("Could not determine current NvChad theme (Event: " .. event_source .. "). Checked vim.g.base46_theme, chadrc, vim.v.colorscheme.", vim.log.levels.WARN, { title = "WezTerm Sync" })
  end

  return current_theme
end

function M.write_theme_to_file(nvchad_theme_name_input)
  local nvchad_theme_name = nvchad_theme_name_input

  -- Sometimes theme names might have "_dark" or similar postfixes from base46 internal variants 
  -- nvchad_theme_name = string.gsub(nvchad_theme_name_input, "_dark$", "")
  -- nvchad_theme_name = string.gsub(nvchad_theme_name, "_light$", "")

  if not nvchad_theme_name or type(nvchad_theme_name) ~= "string" or #nvchad_theme_name == 0 then
    vim.notify("Invalid or empty NvChad theme name received: '" .. tostring(nvchad_theme_name_input) .. "'. Cannot write to WezTerm sync file.", vim.log.levels.WARN, { title = "WezTerm Sync" })
    return
  end

  local wezterm_theme_name = theme_map[nvchad_theme_name] or nvchad_theme_name

  local file = io.open(theme_file_path, "w")
  if file then
    file:write(wezterm_theme_name)
    file:close()
    vim.notify("WezTerm: Wrote '" .. wezterm_theme_name .. "' (from NvChad: '" .. nvchad_theme_name .. "')", vim.log.levels.INFO, { title = "WezTerm Sync" })
  else
    vim.notify("Error writing WezTerm theme file: " .. theme_file_path, vim.log.levels.ERROR, { title = "WezTerm Sync" })
  end
end

local group = vim.api.nvim_create_augroup("WezTermThemeSync", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  pattern = "*",
  callback = function()
    -- Adding a slight delay because vim.g.base46_theme might be updated
    -- just after the ColorScheme event technically fires but before this callback fully executes.
    vim.defer_fn(function()
      local theme_name = M.get_current_nvchad_theme_name("ColorScheme")
      if theme_name then
        M.write_theme_to_file(theme_name)
      end
    end, 50) -- 50ms delay, adjust if needed
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  pattern = "*",
  nested = true,
  callback = function()
    vim.defer_fn(function()
      -- On VimEnter, primarily trust vim.g.base46_theme if set by NvChad,
      -- otherwise try to get it from chadrc.
      local theme_name = M.get_current_nvchad_theme_name("VimEnter")
      if theme_name then
        M.write_theme_to_file(theme_name)
      else
         -- vim.notify("Initial NvChad theme for WezTerm sync not found on VimEnter.", vim.log.levels.WARN, { title = "WezTerm Sync" })
      end
    end, 250) -- Delay slightly (e.g., 250ms) to allow NvChad to fully initialize and set vim.g.base46_theme
  end,
})

-- You can also add a command to manually trigger the sync
vim.api.nvim_create_user_command("WeztermSyncTheme", function()
    local theme_name = M.get_current_nvchad_theme_name("ManualTrigger")
    if theme_name then
        M.write_theme_to_file(theme_name)
        vim.notify("Manual WezTerm theme sync triggered.", vim.log.levels.INFO, { title = "WezTerm Sync" })
    else
        vim.notify("Could not determine NvChad theme for manual sync.", vim.log.levels.WARN, { title = "WezTerm Sync" })
    end
end, {})

return M
