local vt100 = require("vt100")

local rules = vt100.rules

-- [?7[hl]        wrap mode
rules[{"%[", "%?", "7", "[hl]"}] = function(window, _, _, _, nowrap)
  window.nowrap = nowrap == "l"
end

-- helper scroll function
local function set_cursor(window, x, y)
  window.x = math.min(math.max(x, 1), window.width)
  window.y = math.min(math.max(y, 1), window.height)
end

-- -- These DO NOT SCROLL
-- [(%d*)A        move cursor up n lines
-- [(%d*)B        move cursor down n lines
-- [(%d*)C        move cursor right n lines
-- [(%d*)D        move cursor left n lines
rules[{"%[", "%d*", "[ABCD]"}] = function(window, _, n, dir)
  local dx, dy = 0, 0
  n = tonumber(n) or 1
  if dir == "A" then
    dy = -n
  elseif dir == "B" then
    dy = n
  elseif dir == "C" then
    dx = n
  else -- D
    dx = -n
  end
  set_cursor(window, window.x + dx, window.y + dy)
end

-- [Line;ColumnH  Move cursor to screen location v,h
-- [Line;Columnf  ^ same
-- [;H            Move cursor to upper left corner
-- [;f            ^ same
rules[{"%[", "%d*", ";", "%d*", "[Hf]"}] = function(window, _, y, _, x)
  set_cursor(window, tonumber(x) or 1, tonumber(y) or 1)
end

-- [H             move cursor to upper left corner
-- [f             ^ same
rules[{"%[[Hf]"}] = function(window)
  set_cursor(window, 1, 1)
end

-- [K             clear line from cursor right
-- [0K            ^ same
-- [1K            clear line from cursor left
-- [2K            clear entire line
local function clear_line(window, _, n)
  n = tonumber(n) or 0
  local x = (n == 0 and window.x or 1)
  local rep = n == 1 and window.x or (window.width - x + 1)
  window.gpu.fill(x + window.dx, window.y + window.dy, rep, 1, " ")
end
rules[{"%[", "[012]?", "K"}] = clear_line

-- [J             clear screen from cursor down
-- [0J            ^ same
-- [1J            clear screen from cursor up
-- [2J            clear entire screen
rules[{"%[", "[012]?", "J"}] = function(window, _, n)
  clear_line(window, _, n)
  n = tonumber(n) or 0
  local y = n == 0 and (window.y + 1) or 1
  local rep = n == 1 and (window.y - 1) or (window.height)
  window.gpu.fill(1 + window.dx, y + window.dy, window.width, rep, " ")
end

-- [6n            get the cursor position [ EscLine;ColumnR 	Response: cursor is at v,h ]
rules[{"%[", "6", "n"}] = function(window)
  -- this solution puts the response on stdin, but it isn't echo'd
  -- I'm personally fine with the lack of echo
  io.stdin.bufferRead = string.format("%s%s[%d;%dR", io.stdin.bufferRead, string.char(0x1b), window.y, window.x)
end

-- D               scroll up one line -- moves cursor down
-- E               move to next line (acts the same ^, but x=1)
-- M               scroll down one line -- moves cursor up
rules[{"[DEM]"}] = function(window, _, dir)
  if dir == "D" then
    window.y = window.y + 1
  elseif dir == "E" then
    window.y = window.y + 1
    window.x = 1
  else -- M
    window.y = window.y -  1
  end
end

-- Just consume these codes
rules[{"%[", "%?",   "25", "[hl]"}] = function(window) end
rules[{"%[", "%?", "1002", "[hl]"}] = function(window) end
rules[{"%[", "%?", "1004", "[hl]"}] = function(window) end
rules[{"%[", "%?", "1006", "[hl]"}] = function(window) end
rules[{"%[", "%?", "1049", "[hl]"}] = function(window) -- just clear screen for now
  window.gpu.fill(1+window.dx, 1+window.dy, window.width, window.height, " ")
end
rules[{"%[", "%?", "2004", "[hl]"}] = function(window) end
rules[{"%(", "B"}] = function(window) end -- Select character set for rendering (US ASCII)

-- Move cursor absolutely to column (G) or row (d) <number> (default=1)
rules[{"%[", "%d*", "G"}] = function(window) end
rules[{"%[", "%d*", "d"}] = function(window) end

-- Delete <number> characters in front of cursor, shifting things left to fill the space (default=1)
  -- Does not wrap to next line. (Neither do real terminals)
rules[{"%[", "%d*", "P"}] = function(window, _, n)
  n = tonumber(n)
  window.gpu.copy(window.x+n, window.y, -- Copy from x = n+cursor_pos...
                  window.width-window.x-n, 1, -- ...to the end of that line... 
                  window.x,   window.y) -- ...and "shift" it back to cursor's current pos.
  window.gpu.fill(window.width-n, window.y, n, 1, " ") -- Finally, clear the rightmost n spaces to finish the illusion of shifting.
end
-- Make blank <number> characters in front of cursor (default=1).
  -- Does not wrap to next line. (Neither do real terminals)
rules[{"%[", "%d*", "X"}] = function(window, _, n)
  n = tonumber(n)
  window.gpu.fill(window.x, window.y, n, 1, " ")
end
-- Insert <number> blank spaces, shifting things to the right to make space (default=1)
  -- Does not wrap to next line, pushes things off the edge into oblivion (as do real terminals).
  -- Cursor's position does not change.
rules[{"%[", "%d*", "@"}] = function(window, _, n)
  n = tonumber(n)
  window.gpu.copy(window.x, window.y, -- Copy from cursor...
                  window.width-window.x-n, 1, -- ...to the end of that line minus things that would go past the edge...
                  window.x+n, window.y) -- ...and move it n spaces up.
  window.gpu.fill(window.x, window.y, n, 1, " ") -- Finally, clear the n spaces right of the cursor to finish the illusion of shifting.
end

-- Set cursor style (0 blinking block, 1 solid block, 2 underscore...)
-- The space before the q is intentional.
rules[{"%[", "%d", " q"}] = function(window) end

-- Set scrolling region. E.g.:
-- \e[3;8r would set the scrolling region from line 3 to line 8.
-- \e[10r Would set from line 10 to bottom of screen.
-- \e[r from first line to bottom line (whole screen)
rules[{"%[", "[%d;]*", "r"}] = function(window) end
