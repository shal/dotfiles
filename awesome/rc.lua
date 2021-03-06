local awful = require('awful')
local gears = require('gears')
local vicious = require("vicious")
local wibox = require('wibox')
local beautiful = require('beautiful')
local naughty = require('naughty')
local menubar = require('menubar')
require('awful.autofocus')

awful.util.spawn('nitrogen --restore')

lang = 1

-- {{{ Error handling
if awesome.startup_errors then
  naughty.notify({
    preset = naughty.config.presets.critical,
    title = 'Oops, there were errors during startup!',
    text = awesome.startup_errors
  })
else
  os.execute('killall lock')
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal('debug::error', function (err)
    -- Make sure we don't go into an endless error loop
    if in_error then return end
    in_error = true
    naughty.notify({
      preset = naughty.config.presets.critical,
      title = 'Oops, an error happened!',
      text = err
    })
    in_error = false
  end)
end
-- }}}

-- {{{ Variable definitions
theme_path = os.getenv('HOME') .. '/.config/awesome/theme/theme.lua'
beautiful.init(theme_path)

-- This is used later as the default apps to run.
terminal = 'termite'
editor = os.getenv('EDITOR') or 'vim'
editor_cmd = terminal .. ' -e ' .. editor
browser = 'google-chrome-stable'

modkey = 'Mod4'

mykeyboardlayout = awful.widget.keyboardlayout()

-- CPU usage widget
cpuwidget = awful.widget.graph()
-- Graph properties
cpuwidget:set_width(50)
cpuwidget:set_background_color("#494B4F")
cpuwidget:set_color({ type = "linear", from = { 0, 0 }, to = { 10,0 }, stops = { {0, "#FF5656"}, {0.5, "#88A175"},
                    {1, "#AECF96" }}})
-- Register widget
vicious.register(cpuwidget, vicious.widgets.cpu, "$1")

-- Default modkey.
awful.layout.layouts = {
  awful.layout.suit.tile,
  awful.layout.suit.floating,
  awful.layout.suit.fair,
  awful.layout.suit.spiral,
  awful.layout.suit.max,
  awful.layout.suit.max.fullscreen,
  awful.layout.suit.magnifier,
  awful.layout.suit.corner.nw,
}

-- {{{ Helper functions
local function client_menu_toggle_fn()
  local instance = nil

  return function ()
    if instance and instance.wibox.visible then
      instance:hide()
      instance = nil
    else
      instance = awful.menu.clients({ theme = { width = 250 } })
    end
  end
end
-- }}}

local taglist_buttons = gears.table.join(
awful.button({ }, 3, awful.tag.viewtoggle),

awful.button({ }, 1, function(t)
  t:view_only()
end),

awful.button({ }, 4, function(t)
  awful.tag.viewnext(t.screen)
end),

awful.button({ }, 5, function(t)
  awful.tag.viewprev(t.screen)
end),

awful.button({ modkey }, 1, function(t)
  if client.focus then client.focus:move_to_tag(t) end
end),

awful.button({ modkey }, 3, function(t)
  if client.focus then client.focus:toggle_tag(t) end
end)
)

local tasklist_buttons = gears.table.join(
awful.button({ }, 1, function (c)
  if c == client.focus then
    c.minimized = true
  else

    c.minimized = false
    if not c:isvisible() and c.first_tag then
      c.first_tag:view_only()
    end

    client.focus = c
    c:raise()
  end
end),

awful.button({ }, 4, function ()
  awful.client.focus.byidx(1)
end),

awful.button({ }, 5, function ()
  awful.client.focus.byidx(-1)
end)
)

awful.screen.connect_for_each_screen(function(scr)
  awful.tag({
    '1-[WEB]',
    '2-[WORK]',
    '3-[TERM]',
    '4-[LOG]',
    '5-[SSH]',
    '6-[APP]',
    '7-[MISC]',
    '8-[FLOAT]',
    '9-[ROOT]'
  }, scr, awful.layout.layouts[1])

  scr.mypromptbox = awful.widget.prompt()
  scr.mytextclock = awful.widget.textclock()

  scr.myawesomemenu = {
    { 'manual', terminal .. ' -e man awesome' },
    { 'edit config', editor_cmd .. ' ' .. awesome.conffile },
    { 'restart', awesome.restart }
  }

  scr.mymainmenu = awful.menu({
    items = {
      { 'awesome', scr.myawesomemenu, beautiful.awesome_icon },
      { 'terminal', terminal },
      { 'chrome',  browser },
      { 'shutdown', 'shutdown now' },
      { 'reboot', 'reboot' }
    }
  })

  scr.mytaglist = awful.widget.taglist(
  scr,
  awful.widget.taglist.filter.all,
  taglist_buttons
  )

  scr.mytasklist = awful.widget.tasklist(
  scr,
  awful.widget.tasklist.filter.currenttags,
  tasklist_buttons
  )

  scr.mylauncher = awful.widget.launcher({
    image = beautiful.awesome_icon,
    menu = scr.mymainmenu
  })

  scr.mywibox = awful.wibar({
    position = 'top',
    screen = scr
  })

  menubar.utils.terminal = terminal

  scr.mywibox:setup({
    layout = wibox.layout.align.horizontal,
    { -- Left widgets
    layout = wibox.layout.fixed.horizontal,
    scr.mylauncher,
    scr.mytaglist,
    scr.mypromptbox,
  },
  scr.mytasklist, -- Middle widget
  { -- Right widgets
  layout = wibox.layout.fixed.horizontal,
  cpuwidget,
  wibox.widget.systray(),
  mykeyboardlayout,
  scr.mytextclock
}
  })

  -- Mouse bindings
  root.buttons(
    awful.util.table.join(
      awful.button({ }, 3, function () scr.mymainmenu:toggle() end)
    )
  )
end)

-- Key bindings
globalkeys = awful.util.table.join(
awful.key({ modkey }, 'Left', function ()
  awful.tag.viewprev()
end),

awful.key({ modkey }, 'Right', function ()
  awful.tag.viewnext()
end),

-- Fix with deepin screenshots
-- Screenshot
awful.key({ modkey, 'Control' }, 's', function ()
  awful.util.spawn('deepin-screenshot -s ' .. os.getenv('HOME') .. '/junk/img-' .. os.time() .. '.png')
end),

awful.key({ modkey }, ',', function () awful.screen.focus_relative( 1) end),
awful.key({ modkey }, '.', function () awful.screen.focus_relative(-1) end),

awful.key({ modkey, 'Control' }, 'f', function () awful.util.spawn(browser) end),
awful.key({ modkey, 'Control' }, 'r', function () awesome.restart()         end),

awful.key({ modkey, 'Shift' }, 'q', function () awesome.quit() end),

awful.key({ modkey }, 'o', function() awful.client.movetoscreen()              end),
awful.key({ modkey }, 'p', function() menubar.show()                           end),
awful.key({ modkey }, 'a', function () awful.util.spawn('code')                end),
awful.key({ modkey }, 's', function () awful.util.spawn('slack')               end),
awful.key({ modkey }, 't', function () awful.util.spawn('telegram-dektop')     end),
awful.key({ modkey }, 'l', function () os.execute('dm-tool switch-to-greeter') end),
awful.key({ modkey }, 'Return', function () awful.util.spawn(terminal)         end),
awful.key({ modkey }, 'space', function ()
  lang = lang + 1
  if lang == 1 then
    os.execute('setxkbmap -layout ua')
  elseif lang == 2 then
    os.execute('setxkbmap -layout ru')
  elseif lang == 3 then
    os.execute('setxkbmap -layout us')
    lang = 0
  end
end),
awful.key({ modkey }, 'n', function ()
  if client.focus then
    client.focus.minimized = true
  else
    awful.client.restore()
  end
end),

-- Prompt
awful.key({ modkey }, 'r', function () awful.screen.focused().mypromptbox:run() end)
)

awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end)
awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end)
awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end)
awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end)
awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end)
awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end)
awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end)
awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end)


-- Keys for focused client
clientkeys = awful.util.table.join(
  awful.key({ modkey }, 'f', function (c) c.fullscreen = not c.fullscreen end),
  awful.key({ modkey }, 'q', function (c) c:kill() end),
  awful.key({ modkey }, 't', function (c) c.ontop = not c.ontop end),
  awful.key({ modkey }, 'm', function (c) c.maximized = not c.maximized end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
  globalkeys = awful.util.table.join(
  globalkeys,

  awful.key({ modkey }, '#' .. i + 9, function ()
    awful.tag.viewonly(awful.screen.focused().tags[i])
  end),

  awful.key({ modkey, 'Shift' }, '#' .. i + 9, function ()
    if client.focus then
      awful.client.movetotag(awful.screen.focused().tags[i])
    end
  end)
  )
end

-- Set keys
root.keys(globalkeys)

clientbuttons = awful.util.table.join(
awful.button({        }, 1, function (c) client.focus = c; c:raise() end),
awful.button({ modkey }, 1, awful.mouse.client.move),
awful.button({ modkey }, 3, awful.mouse.client.resize)
)

awful.rules.rules = {
  {
    rule = { },
    except = { name = 'desktop' },
    properties = {
      size_hints_honor = false,
      focus = awful.client.focus.filter,
      maximized = false,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
      floating = false
    }
  },
  {
    rule_any = { type = { 'dialog' } },
    properties = {
      floating = true
    },
    callback = function (c)
      awful.placement.centered(c,nil)
      c.shape = function(cr, w, h)
        gears.shape.partially_rounded_rect(cr, w, h, true, true, true, true, 5)
      end
    end
  }
}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal('manage', function (c, startup)
  if c.role == 'locky' then
    -- show all windows
  else
    -- Enable sloppy focus
    c:connect_signal('mouse::enter', function(c)
      if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier and awful.client.focus.filter(c) then
        client.focus = c
      end
    end)

    if not startup then
      -- Set the windows at the slave,
      -- i.e. put it at the end of others instead of setting it master.
      -- awful.client.setslave(c)

      -- Put windows in a smart way, only if they does not set an initial position.
      if not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_overlap(c)
        awful.placement.no_offscreen(c)
      end
    end
  end
end)

os.execute('xset r rate 200 60')
os.execute('nitrogen --restore')
