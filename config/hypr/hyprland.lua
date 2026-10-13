-- Hyprland - Gruvbox (native Lua config, Hyprland >= 0.55)

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "HDMI-A-2", -- new cable (2026-07): full 4K@60, was DP-2 capped at 30Hz
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
local menu        = "noctalia msg panel-toggle launcher"


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- NVIDIA/Ozone vars live in the nix modules (single source of truth);
-- only cursor theming is compositor-specific enough to belong here
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")

-- Steam is XWayland: with force_zero_scaling (below) it renders at native 4K,
-- so its own UI must scale up to match the 1.5x monitor scale
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "1.5")


----------------
---- PLUGINS ----
----------------




-------------------
---- AUTOSTART ----
-------------------

-- polkit agent runs as a systemd user service; starting the session target
-- below is what activates it (greetd launches Hyprland bare)
hl.on("hyprland.start", function()
    -- Hyprland forwards WAYLAND_DISPLAY/DISPLAY to the systemd user manager but
    -- NOT XDG_SESSION_TYPE — without it, apps spawned by user services exit
    -- instantly (spotify: code 1)
    hl.exec_cmd("systemctl --user import-environment XDG_SESSION_TYPE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    -- Noctalia owns the bar, notifications, OSD, launcher, clipboard,
    -- wallpaper, and lock screen.
    hl.exec_cmd("noctalia --daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprsunset") -- night light daemon; darkman flips it at sunset (home/default.nix)
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Colors come from the active theme (~/.config/theme/current, flipped by the
-- `theme` CLI); fallback keeps the compositor usable if the symlink is missing
local themeOk, theme = pcall(dofile, os.getenv("HOME") .. "/.config/theme/current/hypr.lua")
if not themeOk or type(theme) ~= "table" then
    theme = {
        active   = { "rgba(fe8019ee)", "rgba(fabd2fee)" },
        inactive = "rgba(504945aa)",
        shadow   = "rgba(1d2021ee)",
    }
end

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
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
        -- Hardware cursors work on NVIDIA 555+ (we're on 595): the old
        -- no_hardware_cursors workaround forced a full composite on every
        -- mouse move, making scrolling/pointer motion feel laggy at 4K
        no_hardware_cursors = false,
    },

    decoration = {
        rounding         = 0,

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
            -- xray: blur samples the wallpaper only, so scrolling text in a
            -- transparent terminal no longer recomputes blur over 4K each frame
            xray     = true,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    xwayland = {
        -- Render X11 apps (Steam, etc.) at native resolution instead of
        -- upscaling a 1x buffer to the monitor's 1.5x scale (fixes blur)
        force_zero_scaling = true,
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
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { desc = "File manager" })
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("noctalia msg session lock"), { desc = "Lock screen" })

-- Windows. Application-level Cmd shortcuts pass through to xremap; only
-- macOS-style desktop controls remain global.
hl.bind(mainMod .. " + Tab", hl.dsp.window.cycle_next(), { desc = "Switch window (Cmd+Tab style)" })
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.window.cycle_next("prev"), { desc = "Switch window backwards" })
hl.bind(mainMod .. " + M", hl.dsp.window.move({ workspace = "special:magic" }),
    { desc = "Minimize to scratchpad (Cmd+M style)" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit(), { desc = "Exit Hyprland" })
hl.bind(mainMod .. " + ALT + W", hl.dsp.window.close(), { desc = "Force-close active window" })
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen(), { desc = "Fullscreen (macOS style)" })

-- Clipboard history
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"),
    { desc = "Clipboard history" })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | swappy -f -"), { desc = "Screenshot region" })
-- In Mac mode, the Air75 V3's dedicated screenshot key emits Cmd+Shift+4.
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | swappy -f -"),
    { desc = "Screenshot region (NuPhy key)" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | swappy -f -"), { desc = "Screenshot full screen" })

-- Screen OCR: select a region, text lands in the clipboard (tesseract comes
-- from modules/desktop.nix)
hl.bind(mainMod .. " + ALT + O",
    hl.dsp.exec_cmd(
        "grim -g \"$(slurp -d)\" - | tesseract stdin stdout 2>/dev/null | wl-copy" ..
        " && notify-send -t 3000 'OCR' \"$(wl-paste | head -c 200)\""),
    { desc = "OCR region to clipboard" })

-- Focus with SUPER+arrows. xremap leaves these keys compositor-owned so
-- workspace and window navigation keep working in every GUI app.
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), { desc = "Focus left" })
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), { desc = "Focus down" })
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), { desc = "Focus up" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { desc = "Focus right" })

-- Move windows (arrows, same reason as above; not shadowed by xremap)
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }), { desc = "Move window left" })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }), { desc = "Move window down" })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }), { desc = "Move window up" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { desc = "Move window right" })

-- SUPER+[0-9] switches workspaces; SUPER+SHIFT+[0-9] moves windows.
-- Cmd+Shift+4 is the NuPhy screenshot key, so moving a window to workspace 4
-- adds Ctrl to avoid that firmware-level conflict.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    local moveMods = i == 4 and (mainMod .. " + CTRL + SHIFT + ") or (mainMod .. " + SHIFT + ")
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }),
        { desc = "Go to workspace " .. i })
    hl.bind(moveMods .. key, hl.dsp.window.move({ workspace = i }),
        { desc = "Move window to workspace " .. i })
end

-- Special workspace (scratchpad). Cmd+Option avoids app save shortcuts while
-- keeping one compositor-owned shortcut.
hl.bind(mainMod .. " + ALT + S", hl.dsp.workspace.toggle_special("magic"),
    { desc = "Toggle scratchpad" })

-- Mouse
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Resize window" })

-- Media
-- Volume OSD is noctalia's — one less daemon than swayosd
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("noctalia msg volume-up"),
    { locked = true, repeating = true, desc = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("noctalia msg volume-down"),
    { locked = true, repeating = true, desc = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("noctalia msg volume-mute"),
    { locked = true, desc = "Mute" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Play/pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, desc = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, desc = "Previous track" })

-- Game mode: flip the panel between 4K desktop and native 1440p for CS2.
-- CS2 on Linux has no exclusive fullscreen, so matching the monitor to the
-- game's render res is the only scaling-free way to fill the screen with a
-- 1440p image (gamescope breaks mouse input on this NVIDIA setup).
-- NOTE: config reloads reassert the 4K monitor block above — reload = desktop mode.
hl.bind(mainMod .. " + CTRL + G", function()
    local m = hl.get_monitor("HDMI-A-2")
    if m and m.width > 2560 then
        hl.monitor({ output = "HDMI-A-2", mode = "2560x1440@59.95", position = "0x0", scale = "1" })
        hl.dispatch(hl.dsp.exec_cmd("notify-send -t 2000 'Game mode' '1440p native'"))
    else
        hl.monitor({ output = "HDMI-A-2", mode = "3840x2160@60", position = "0x0", scale = "1.5" })
        hl.dispatch(hl.dsp.exec_cmd("notify-send -t 2000 'Desktop mode' '4K'"))
    end
end, { desc = "Toggle 1440p game mode / 4K desktop" })

-- Theme + wallpaper (the `theme` CLI lives in home/default.nix; wallpaper
-- rendering + picker panel are noctalia's)
hl.bind(mainMod .. " + ALT + T", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"),
    { desc = "Wallpaper picker" })
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("theme toggle"),
    { desc = "Toggle light/dark mode" })

-- Power menu (noctalia session menu)
hl.bind(mainMod .. " + BackSpace", hl.dsp.exec_cmd("noctalia msg panel-toggle session"),
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
    name  = "float-pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
})

-- Keybind cheatsheet terminal (scripts/keybinds.sh)
hl.window_rule({
    name  = "float-keybinds",
    match = { class = "^keybinds\\.cheatsheet$" },
    float = true,
})

-- CS2 spawns secondary windows (server browser, etc.); float them all so
-- they overlay the game instead of tiling next to it and shrinking it
hl.window_rule({
    name  = "float-cs2",
    match = { class = "^(cs2)$" },
    float = true,
})
