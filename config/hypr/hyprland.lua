-- Hyprland - Tokyo Night (native Lua config, Hyprland >= 0.55)

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "HDMI-A-1", -- new cable (2026-07): full 4K@60, was DP-2 capped at 30Hz
    mode     = "3840x2160@60",
    position = "0x0",
    scale    = "1.5", -- 27" 4K sweet spot: 1440p-sized workspace, 4K sharpness
})

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "thunar"
local menu        = "walker"


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- NVIDIA/Ozone vars live in the nix modules (single source of truth);
-- only cursor theming is compositor-specific enough to belong here
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")


----------------
---- PLUGINS ----
----------------

-- Dynamic cursors: physics tilt/stretch + shake-to-find. The .so is a
-- home-manager symlink (home/default.nix); guard so a fresh system without
-- it doesn't error the whole config.
local dc = os.getenv("HOME") .. "/.local/share/hypr-plugins/dynamic-cursors.so"
if io.open(dc, "r") then
    hl.plugin.load(dc)
end


-------------------
---- AUTOSTART ----
-------------------

-- polkit agent and wallpaper (awww) run as systemd user services; starting the
-- session target below is what activates them (greetd launches Hyprland bare)
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("walker --gapplication-service") -- resident for instant opens
    hl.exec_cmd("dunst")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Colors come from the active theme (~/.config/theme/current, flipped by the
-- `theme` CLI); fallback keeps the compositor usable if the symlink is missing
local themeOk, theme = pcall(dofile, os.getenv("HOME") .. "/.config/theme/current/hypr.lua")
if not themeOk or type(theme) ~= "table" then
    theme = {
        active   = { "rgba(7aa2f7ee)", "rgba(bb9af7ee)" },
        inactive = "rgba(414868aa)",
        shadow   = "rgba(1a1a1aee)",
    }
end

hl.config({
    general = {
        gaps_in          = 1,
        gaps_out         = 1,
        border_size      = 1,

        col              = {
            active_border   = { colors = theme.active, angle = 45 },
            inactive_border = theme.inactive,
        },

        resize_on_border = true,
        layout           = "dwindle",
    },

    cursor = {
        inactive_timeout    = 30,
        no_hardware_cursors = true,
    },

    decoration = {
        rounding         = 0,

        active_opacity   = 0.95,
        inactive_opacity = 0.85,

        shadow           = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = theme.shadow,
        },

        blur             = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            vibrancy = 0.2,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        vrr                      = 1,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout     = "us",
        kb_options    = "caps:escape",

        repeat_rate   = 35,
        repeat_delay  = 200,
        follow_mouse  = 1,
        sensitivity   = 0,
        accel_profile = "flat",

        touchpad      = {
            natural_scroll = true,
            tap_to_click   = true,
        },
    },
})


-------------------
---- KEYBINDS -----
-------------------

local mainMod = "SUPER"

-- Every bind carries a desc: it documents the config AND feeds the
-- SUPER+SHIFT+/ cheatsheet (scripts/keybinds.sh reads them via hyprctl)

-- Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { desc = "Open terminal" })
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu), { desc = "App launcher (Spotlight-style)" })
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu), { desc = "App launcher" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { desc = "File manager" })
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("hyprlock"), { desc = "Lock screen" })

-- Windows (SUPER = Cmd: Q quits, W closes, M "minimizes", Tab switches)
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { desc = "Close window" })
hl.bind(mainMod .. " + W", hl.dsp.window.close(), { desc = "Close window (Cmd+W style)" })
hl.bind(mainMod .. " + Tab", hl.dsp.window.cycle_next(), { desc = "Switch window (Cmd+Tab style)" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next("prev"), { desc = "Switch window backwards" })
hl.bind(mainMod .. " + M", hl.dsp.window.move({ workspace = "special:magic" }),
    { desc = "Minimize to scratchpad (Cmd+M style)" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit(), { desc = "Exit Hyprland" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { desc = "Toggle floating" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(), { desc = "Fullscreen" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { desc = "Pseudotile" })
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"), { desc = "Toggle split direction" })

-- Clipboard
 hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | walker --dmenu | cliphist decode | wl-copy"),
    { desc = "Clipboard history" })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | swappy -f -"), { desc = "Screenshot region" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | swappy -f -"), { desc = "Screenshot full screen" })

-- Focus (vim keys + arrows)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }), { desc = "Focus left" })
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }), { desc = "Focus down" })
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }), { desc = "Focus up" })
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }), { desc = "Focus right" })
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { desc = "Focus left" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { desc = "Focus down" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { desc = "Focus up" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { desc = "Focus right" })

-- Move windows
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }), { desc = "Move window left" })
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }), { desc = "Move window down" })
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }), { desc = "Move window up" })
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }), { desc = "Move window right" })

-- Workspaces: SUPER+[0-9] switch, SUPER+SHIFT+[0-9] move window
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }),
        { desc = "Go to workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
        { desc = "Move window to workspace " .. i })
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { desc = "Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }),
    { desc = "Move window to scratchpad" })

-- Mouse
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Resize window" })

-- Media
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise --max-volume 100"),
    { locked = true, repeating = true, desc = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
    { locked = true, repeating = true, desc = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"),
    { locked = true, desc = "Mute" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Play/pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, desc = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, desc = "Previous track" })

-- Gaming
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("steam"), { desc = "Launch Steam" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("runelite"), { desc = "Launch RuneLite" })

-- Theme + wallpaper (the `theme` CLI lives in home/default.nix)
hl.bind(mainMod .. " + CTRL + T", hl.dsp.exec_cmd("theme-picker"),
    { desc = "Theme/wallpaper picker" })
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("theme toggle"),
    { desc = "Toggle light/dark mode" })
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("systemctl --user restart wallpaper"),
    { desc = "Restart wallpaper service" })
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("theme wallpaper"),
    { desc = "Reset wallpaper (current theme)" })

-- Power menu (Omarchy-style)
hl.bind(mainMod .. " + BackSpace", hl.dsp.exec_cmd("~/.config/hypr/scripts/power-menu.sh"),
    { desc = "Power menu (lock/logout/reboot/shutdown)" })

-- Cheatsheet: this very list
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds.sh"),
    { desc = "Show this keybind cheatsheet" })


----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "^(pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name  = "float-nm-editor",
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})

hl.window_rule({
    name  = "float-blueman",
    match = { class = "^(blueman-manager)$" },
    float = true,
})

hl.window_rule({
    name  = "float-pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
})
