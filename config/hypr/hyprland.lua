-- Hyprland - Tokyo Night (native Lua config, Hyprland >= 0.55)

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "DP-2",
    mode     = "3840x2160@30",
    position = "0x0",
    scale    = "2",
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
local menu        = "wofi --show drun"


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- NVIDIA/Ozone vars live in the nix modules (single source of truth);
-- only cursor theming is compositor-specific enough to belong here
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")


-------------------
---- AUTOSTART ----
-------------------

-- polkit agent and wallpaper (awww) run as systemd user services; starting the
-- session target below is what activates them (greetd launches Hyprland bare)
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("dunst")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,
        border_size      = 1,

        col              = {
            active_border   = { colors = { "rgba(7aa2f7ee)", "rgba(bb9af7ee)" }, angle = 45 },
            inactive_border = "rgba(414868aa)",
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
            color        = "rgba(1a1a1aee)",
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

-- Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("hyprlock"))

-- Windows
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit")) -- dwindle only

-- Clipboard
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp -d)\" - | swappy -f -"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | swappy -f -"))

-- Focus (vim keys + arrows)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))

-- Move windows
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Gaming
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("steam"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("runelite"))

-- Wallpaper (useful after rebuilds)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("systemctl --user restart wallpaper"))
hl.bind(mainMod .. " + CTRL + W",
    hl.dsp.exec_cmd("awww img /home/pjanderson/nixos/config/wallpapers/tokyonight-nix.png --transition-type fade"))


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
