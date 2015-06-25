--require "pl.strict"
local modal_hotkey = require("mjolnir._asm.modal_hotkey")
local hydra = require("mjolnir._asm.hydra")
local window = require "mjolnir.window"
local screen = require "mjolnir.screen"
local hotkey = require "mjolnir.hotkey"
local geometry = require "mjolnir.geometry"
local fnutils = require "mjolnir.fnutils"
local appfinder = require "mjolnir.cmsj.appfinder"
local caffeinate = require "mjolnir.cmsj.caffeinate"
local notify = require "mjolnir._asm.notify"
local screenwatch = require "mjolnir._asm.watcher.screen"
local alert = require "mjolnir.alert"
-- local mjolnir = require "mjolnir"

-- Define some keyboard modifier variables
-- (Node: Capslock bound to cmd+alt+ctrl+shift via Seil and Karabiner)
local alt = {"alt"}
-- local hyper = {"cmd", "alt", "ctrl", "shift"}
local hyper = {"cmd", "alt", "ctrl"}

-- Define some window rects for layout purposes
local left30 = geometry.rect(0, 0, 0.3, 1)
local left50 = geometry.rect(0, 0, 0.5, 1)
local left70 = geometry.rect(0, 0, 0.7, 1)
local right30 = geometry.rect(0.7, 0, 0.3, 1)
local right50 = geometry.rect(0.5, 0, 0.5, 1)
local right70 = geometry.rect(0.3, 0, 0.7, 1)
local top = geometry.rect(0, 0, 1, 0.5)
local topleft = geometry.rect(0, 0, 0.5, 0.5)
local left = geometry.rect(0, 0, 0.5, 1)
local bottomleft = geometry.rect(0, 0.5, 0.5, 0.5)
local bottom = geometry.rect(0, 0.5, 1, 0.5)
local bottomright = geometry.rect(0.5, 0.5, 0.5, 0.5)
local right = geometry.rect(0.5, 0, 0.5, 1)
local topright = geometry.rect(0.5, 0, 0.5, 0.5)

local maximized = geometry.rect(0, 0, 1, 1)

-- Define monitor names for layout purposes
local display_laptop = "Built-in Display"
local display_monitor = "Thunderbolt Display"


k = modal_hotkey.new({"cmd", "shift"}, "L")

function k:entered() alert.show('Entering layout hack', .4) end
function k:exited()  alert.show('Canceling layout hack', .25)  end

k:bind({}, 'escape', function() k:exit() end)
k:bind({}, 'Q', function() k:exit() end)
-- k:bind({}, 'J', function() alert.show("Pressed J") end)

-- Define window layouts
--   Format reminder:
--     {"App name", "Window name", "Display Name", "unitrect", "framerect", "fullframerect"},
local internal_display = {
    {"Slack",             nil,          display_laptop, maximized, nil, nil},
    {"Evernote",          nil,          display_laptop, maximized, nil, nil},
    {"iTunes",            "iTunes",     display_laptop, maximized, nil, nil},
    {"Google Chrome",   nil, display_monitor, left50, nil, nil}
}

local dual_display = {
    {"Google Chrome",     nil, display_monitor, right50, nil, nil},
    {"Safari",            nil,          display_monitor, maximized, nil, nil},
}

-- Helper functions
function toggle_fullscreen()
    local win = window.focusedwindow()
    local isfull = win:isfullscreen()
    if isfull ~= nil then
        win:setfullscreen(not isfull)
    end
end

function toggle_console()
    local console = appfinder.window_from_window_title("Mjolnir Console")
    if console and (console ~= window.focusedwindow()) then
        console:focus()
    elseif console then
        console:close()
    else
        mjolnir.openconsole()
    end
end

function relocate_window(win, src, dst)
    -- Moves a window between screens, retaining relative proportions
    local f = win:frame()
    local old_screen = src:frame()
    local new_screen = dst:frame()
    local h_perc = f.h / old_screen.h
    local w_perc = f.w / old_screen.w
    local x_perc = math.abs(old_screen.x - f.x) / old_screen.w
    local y_perc = (f.y - old_screen.y) / old_screen.h

    f.x = new_screen.x + (new_screen.w * x_perc)
    f.y = new_screen.y + (new_screen.h * y_perc)
    f.w = new_screen.w * w_perc
    f.h = new_screen.h * h_perc

    win:setframe(f)
end

function move_window_one_screen_west()
    local win = window.focusedwindow()
    local dst = win:screen():towest()
    if dst ~= nil then
        relocate_window(win, win:screen(), dst)
    end
end

function move_window_one_screen_east()
    local win = window.focusedwindow()
    local dst = win:screen():toeast()
    if dst ~= nil then
        relocate_window(win, win:screen(), dst)
    end
end

function toggle_display_sleep()
    local is_sleep = caffeinate.toggle("DisplayIdle")

    local msg = "Display is now "
    if not is_sleep then
        msg = msg .. "de-"
    end
    msg = msg .. "caffeinated."

    notify.show("Mjolnir", "", msg, "")
end

function apply_layout(layout)
-- TODO: Add optional debugging
-- Layout parameter should be a table where each row takes the form of:
--  {"App name", "Window name","Display Name", "unitrect", "framerect", "fullframerect"},
--  First three items in each row are strings
--  Second three items are rects that specify the position of the window. The first one that is
--   not nil, wins.
--  unitrect is a rect passed to window:movetounit()
--  framerect is a rect passed to window:setframe()
--      If either the x or y components of framerect are negative, they will be applied as
--      offsets from the width or height of screen:frame(), respectively
--  fullframerect is a rect passed to window:setframe()
--      If either the x or y components of fullframerect are negative, they will be applied
--      as offsets from the width or height of screen:fullframe(), respectively
    for n,_row in pairs(layout) do
        local app = nil
        local wins = nil
        local display = nil
        local displaypoint = nil
        local unit = _row[4]
        local frame = _row[5]
        local fullframe = _row[6]
        local windows = nil

        -- Find the application's object, if wanted
        if _row[1] then
            app = appfinder.app_from_name(_row[1])
            if not app then
                print("Unable to find app: " .. _row[1])
            end
        end

        -- Find the destination display, if wanted
        if _row[3] then
            local displays = fnutils.filter(screen.allscreens(), function(screen) return screen:name() == _row[3] end)
            if displays then
                -- TODO: This is bogus, multiple identical monitors will be impossible to lay out
                display = displays[1]
            end
            if not display then
                print("Unable to find display: " .. _row[3])
            else
                displaypoint = geometry.point(display:frame().x, display:frame().y)
            end
        end

        -- Find the matching windows, if any
        if _row[2] then
            if app then
                wins = fnutils.filter(app:allwindows(), function(win) return win:title() == _row[2] end)
            else
                wins = fnutils.filter(window:allwindows(), function(win) return win:title() == _row[2] end)
            end
        elseif app then
            wins = app:allwindows()
        end

        -- Apply the display/frame positions requested, if any
        if not wins then
            print(_row[1],_row[2])
            print("No windows matched, skipping.")
        else
            for m,_win in pairs(wins) do
                local winframe = nil
                local screenrect = nil

                -- Move window to destination display, if wanted
                if display then
                    _win:settopleft(displaypoint)
                end

                -- Apply supplied position, if any
                if unit then
                    _win:movetounit(unit)
                elseif frame then
                    winframe = frame
                    screenrect = _win:screen():frame()
                elseif fullframe then
                    winframe = fullframe
                    screenrect = _win:screen():fullframe()
                end

                if winframe then
                    if winframe.x < 0 or winframe.y < 0 then
                        if winframe.x < 0 then
                            winframe.x = screenrect.w + winframe.x
                        end
                        if winframe.y < 0 then
                            winframe.y = screenrect.h + winframe.y
                        end
                    end
                    _win:setframe(winframe)
                end
            end
        end
    end
end

-- -- hotkey.bind(hyper, 'r', mjolnir.reload);
-- hotkey.bind(hyper, "r", function()
--         alert.show("reloading config")
--         mjolnir.reload()
--         alert.show("reloaded config")
-- end)
--
--
-- -- Hotkeys to move windows between screens
-- hotkey.bind(hyper, 'Left', move_window_one_screen_west)
-- hotkey.bind(hyper, 'Right', move_window_one_screen_east)
--
-- -- Hotkeys to resize windows absolutely
-- hotkey.bind(hyper, 'o', function() window.focusedwindow():movetounit(top) end)
-- hotkey.bind(hyper, 'i', function() window.focusedwindow():movetounit(topleft) alert.show("I: top left") end)
-- hotkey.bind(hyper, 'j', function() window.focusedwindow():movetounit(left) alert.show("J: ◧", 1) end)
-- hotkey.bind(hyper, 'n', function() window.focusedwindow():movetounit(bottomleft) end)
-- hotkey.bind(hyper, 'm', function() window.focusedwindow():movetounit(bottom) end)
-- hotkey.bind(hyper, ',', function() window.focusedwindow():movetounit(bottomright) end)
-- hotkey.bind(hyper, 'l', function() window.focusedwindow():movetounit(right) end)
-- hotkey.bind(hyper, 'p', function() window.focusedwindow():movetounit(topright) end)
-- -- hotkey.bind(hyper, 'k', function() window.focusedwindow():maximize() end)
-- hotkey.bind(hyper, 'k', function() window.focusedwindow():movetounit(maximized) end)
-- hotkey.bind(hyper, 'f', toggle_fullscreen)
-- hotkey.bind(hyper, 'space', toggle_fullscreen)
--
-- -- Hotkeys to trigger defined layouts
-- hotkey.bind(hyper, '1', function() apply_layout(internal_display) end)
-- hotkey.bind(hyper, '2', function() apply_layout(dual_display) end)
--
-- -- Misc hotkeys
-- hotkey.bind(hyper, 'y', toggle_console)
-- hotkey.bind(hyper, 'n', function() os.execute("open ~") end)
-- hotkey.bind(hyper, 'c', toggle_display_sleep)
-- hotkey.bind(hyper, 'h', function()
--     alert.show(
--         "P\t\t\t◳\n" ..
--         "I\t\t\t◰\n" ..
--         "N\t\t\t◱\n" ..
--         ",\t\t\t◲\n" ..
--         "\n" ..
--         "J\t\t\t◧\n" ..
--         "L\t\t\t◨\n" ..
--         "M\t\t\t⬓\n" ..
--         "O\t\t\t⬒\n" ..
--         "\n" ..
--         "K\t\t\t◼\n" ..
--         "H\t\t\tHelp" ..
--         "\n" , 3
--     )
-- end)
--

k:bind({}, "r", function()
        alert.show("reloading config")
        mjolnir.reload()
        alert.show("reloaded config")
end)


-- Hotkeys to move windows between screens
k:bind({}, 'Left', move_window_one_screen_west)
k:bind({}, 'Right', move_window_one_screen_east)

-- Hotkeys to resize windows absolutely
k:bind({}, 'o', function() window.focusedwindow():movetounit(top) k:exit() end)
k:bind({}, 'i', function() window.focusedwindow():movetounit(topleft) k:exit() end)
k:bind({}, 'j', function() window.focusedwindow():movetounit(left) k:exit() end)
k:bind({}, 'n', function() window.focusedwindow():movetounit(bottomleft) k:exit() end)
k:bind({}, 'm', function() window.focusedwindow():movetounit(bottom) k:exit() end)
k:bind({}, ',', function() window.focusedwindow():movetounit(bottomright) k:exit() end)
k:bind({}, 'l', function() window.focusedwindow():movetounit(right) k:exit() end)
k:bind({}, 'p', function() window.focusedwindow():movetounit(topright) k:exit() end)
-- k:bind({}, 'k', function() window.focusedwindow():maximize() end)
k:bind({}, 'k', function() window.focusedwindow():movetounit(maximized) k:exit() end)
k:bind({}, 'f', function() toggle_fullscreen() k:exit() end)
k:bind({}, 'space', function() toggle_fullscreen() k:exit() end)

-- Hotkeys to trigger defined layouts
k:bind({}, '1', function() apply_layout(internal_display) end)
k:bind({}, '2', function() apply_layout(dual_display) end)

-- Misc hotkeys
k:bind({}, 'y', toggle_console)
k:bind({}, 'n', function() os.execute("open ~") end)
k:bind({}, 'c', toggle_display_sleep)
k:bind({}, 'h', function()
    alert.show(
        "P\t\t\t◳\n" ..
        "I\t\t\t◰\n" ..
        "N\t\t\t◱\n" ..
        ",\t\t\t◲\n" ..
        "\n" ..
        "J\t\t\t◧\n" ..
        "L\t\t\t◨\n" ..
        "M\t\t\t⬓\n" ..
        "O\t\t\t⬒\n" ..
        "\n" ..
        "K\t\t\t◼\n" ..
        "H\t\t\tHelp" ..
        "\n" , 3
    )
end)

alert.show("Mjolnir loaded.")


