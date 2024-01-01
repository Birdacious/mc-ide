local text = require("text")

local rules = {}
local vt100 = {rules=rules}
local full

rules[{"%[", "[%d;]*", "m"}] = function(window, _, number_text)
  local setFg,setBg = window.gpu.setForeground,window.gpu.setBackground

  number_text = " _ " .. number_text:gsub("^;$", ""):gsub(";", " _ ") .. " _ "
  local parts = text.internal.tokenize(number_text)
  local last_was_break

  local loops_to_skip = 0
  for part_i,part in ipairs(parts) do
    if loops_to_skip > 0 then loops_to_skip=loops_to_skip-1; goto continue end -- Because some codes span across multiple ';'s.
    local n = tonumber(part[1].txt)

    -- TODO tokenize including delims ruins loops_to_skip
      -- Put loops_to_skip after "if not n then continue" instead.
    if not n then -- tokenize breaks string into tokens _including delimiters_. if not n, then n is a delim.
      if last_was_break then n=0 end -- If two breaks in a row or ending with a break e.g. \27[;m or \27[1;m or \27[;;m, interpreted as a reset
      last_was_break = true
      goto continue -- Otherwise n is just a normal break, ignore and move to next item
    else last_was_break = false end 

    if n == 0 then -- Reset
      window.blink=false
      window.flip=false
      setFg(0xFFFFFF)
      setBg(0x0)

    -- elseif n == 1 then end -- Bold, unimplemented.
    -- elseif n == 2 then end -- Dim, unimplemented.
    -- elseif n == 3 then end -- Italic, unimplemented.
    -- elseif n == 4 then end -- Underline, unimplemented.
    elseif n == 5 then window.blink=true -- Blinking text. Not a toggle, stays until unset or full reset.
    elseif n == 7 then window.flip=true -- Reverse fg/bg color. Not a toggle, stays until unset or full reset.
    -- elseif n == 8 then end -- Invisible, unimplemented.
    -- elseif n == 9 then end -- Strikethrough, unimplemented.
    -- elseif n == 21 then end -- Double underline, unimmplemented.
    -- elseif n == 22 then end -- Unset bold & dim, unimplemented.
    -- elseif n == 23 then end -- Unset italic, unimplemented.
    -- elseif n == 24 then end -- Unset underline, unimplemented.
    elseif n == 25 then window.blink=false
    elseif n == 27 then window.flip=false
    -- elseif n == 28 then end -- Unset invisible, unimplemented
    -- elseif n == 29 then end -- Unset strikethrough, unimplemented.
    end

    if window.flip then setFg,setBg = setBg,setFg end
    --if window.flip then -- TODO: test this instead?
    --  local rgb,pal = setBg(window.gpu.getForeground)
    --  setFG(pal or rgb, not not pal)
    --  setFg,setBg = setBg,setFg
    --end

    -- Colors
    local color3_palette = {0x0,0xff0000,0x00ff00,0xffff00,0x0000ff,0xff00ff,0x00B6ff,0xffffff}
    -- n = 30-37 and 40-47 are shortcuts for basic 3b foreground and background colors. 
    -- n = 38 and 48 are for more advanced colors.
    -- n = 39 and 49 set to default.
    if     n >= 30 and n <= 37 then setFg(color3_palette[n-29])
    elseif n >= 40 and n <= 47 then setBg(color3_palette[n-39])
    elseif n == 39             then setFg(color3_palette[8])
    elseif n == 49             then setBg(color3_palette[1])

    elseif n == 38 or n == 48 then
      local color
      local n2 = tonumber(parts[part_i+2][1].txt) -- +2 because parts includes delimiters

      if n2 == 2 then -- True color (24b). OC can't actually display true color, but it can still do its best given true color numbers e.g. 0x123456.
        local n3 = tonumber(parts[part_i+4][1].txt)
        local n4 = tonumber(parts[part_i+6][1].txt)
        local n5 = tonumber(parts[part_i+8][1].txt)
        if n3 and n4 and n5 and (n3 >= 0 and n4 >= 0 and n5 >= 0 and n3 <= 255 and n4 <= 255 and n5 <= 255) then
          loops_to_skip = 4
          local r = n3*256*256 -- Bitshift so 0xRR0000
          local g = n4*256     --             0x00GG00
          local b = n5         --             0x0000BB
          color = r+g+b -- 0xRRGGBB
        end

      elseif n2 == 5 then -- 256-color (8b).
        local n3 = tonumber(parts[part_i+4][1].txt)
        if n3 then
          loops_to_skip = 2
          if n3 >= 0 and n3 <= 239 then
            -- OC uses a 6-8-5 r-g-b palette. Color table here: https://ocdoc.cil.li/component:gpu
            local r = math.floor( n3              /40)
            local g = math.floor((n3-(40*r)      )/5)
            local b = math.floor((n3-(40*r)-(5*g))/1)
                  r = (r==0 and 0x000000) or (r==1 and 0x330000) or (r==2 and 0x660000) or (r==3 and 0x990000) or (r==4 and 0xCC0000) or (r==5 and 0xFF0000)
                  g = (g==0 and 0x000000) or (g==1 and 0x002400) or (g==2 and 0x004900) or (g==3 and 0x006D00) or (g==4 and 0x009200) or (g==5 and 0x00B600) or (g==6 and 0x00DB00) or (g==7 and 0x00FF00)
                  b = (b==0 and 0x000000) or (b==1 and 0x000040) or (b==2 and 0x000080) or (b==3 and 0x0000C0) or (b==4 and 0x0000FF)
            color = r+g+b

          elseif n3 >= 240 and n3 <= 255 then -- Special values reserved for greyscale
            color = (n3==240 and 0x0F0F0F) or (n3==241 and 0x1E1E1E) or (n3==242 and 0x2D2D2D) or (n3==243 and 0x3C3C3C) or (n3==244 and 0x4B4B4B) or (n3==245 and 0x5A5A5A) or (n3==246 and 0x696969) or (n3==247 and 0x787878) or (n3==248 and 0x878787) or (n3==249 and 0x969696) or (n3==250 and 0xA5A5A5) or (n3==251 and 0xB4B4B4) or (n3==252 and 0xC3C3C3) or (n3==253 and 0xD2D2D2) or (n3==254 and 0xE1E1E1) or (n3==255 and 0xF0F0F0)
          end
        end
      end

      if color and  n == 38 then setFg(color) elseif n == 48 then setBg(color) end
    end
    ::continue::
  end 
end

-- Original OpenComputers code
-- colors, blinking, and reverse
-- [%d+;%d+;..%d+m
  -- prefix and suffix ; act as reset
  -- e.g. \27[41;m is actually 41 followed by a reset
-- cost: 2,250
--rules[{"%[", "[%d;]*", "m"}] = function(window, _, number_text)
--  local colors = {0x0,0xff0000,0x00ff00,0xffff00,0x0000ff,0xff00ff,0x00B6ff,0xffffff}
--  local fg, bg = window.gpu.setForeground, window.gpu.setBackground
--  if window.flip then
--    fg, bg = bg, fg
--  end
--  number_text = " _ " .. number_text:gsub("^;$", ""):gsub(";", " _ ") .. " _ "
--  local parts = text.internal.tokenize(number_text)
--  local last_was_break
--  for _,part in ipairs(parts) do
--    local num = tonumber(part[1].txt)
--    last_was_break, num = not num, num or last_was_break and 0
--
--    local flip = num == 7
--    if flip then
--      if not window.flip then
--        local rgb, pal = bg(window.gpu.getForeground())
--        fg(pal or rgb, not not pal)
--        fg, bg = bg, fg
--      end
--    elseif num == 5 then
--      window.blink = true
--    elseif num == 0 then
--      bg(colors[1])
--      fg(colors[8])
--    elseif num then
--      num = num - 29
--      local set = fg
--      if num > 10 then
--        num = num - 10
--        set = bg
--      end
--      local color = colors[num]
--      if color then
--        set(color)
--      end
--    end
--    window.flip = flip
--  end
--end

local function save_attributes(window, seven, s)
  if seven == "7" or s == "s" then
    window.saved =
    {
      window.x,
      window.y,
      {window.gpu.getBackground()},
      {window.gpu.getForeground()},
      window.flip,
      window.blink
    }
  else
    local data = window.saved or {1, 1, {0x0}, {0xffffff}, window.flip, window.blink}
    window.x = data[1]
    window.y = data[2]
    window.gpu.setBackground(table.unpack(data[3]))
    window.gpu.setForeground(table.unpack(data[4]))
    window.flip = data[5]
    window.blink = data[6]
  end
end

-- 7               save cursor position and attributes
-- 8               restore cursor position and attributes
rules[{"[78]"}] = save_attributes

-- s               save cursor position
-- u               restore cursor position
rules[{"%[", "[su]"}] = save_attributes

-- returns: anything that failed to parse
function vt100.parse(window)
  if window.output_buffer:sub(1, 1) ~= "\27" then
    return ""
  end
  local any_valid

  for rule,action in pairs(rules) do
    local last_index = 1 -- start at 1 to skip the \27
    local captures = {}
    for _,pattern in ipairs(rule) do
      if last_index >= #window.output_buffer then
        any_valid = true
        break
      end
      local si, ei, capture = window.output_buffer:find("^(" .. pattern .. ")", last_index + 1)
      if not si then
        break
      end
      captures[#captures + 1] = capture
      last_index = ei
    end

    if #captures == #rule then
      action(window, table.unpack(captures))
      window.output_buffer = window.output_buffer:sub(last_index + 1)
      return ""
    end
  end

  if not full then
    -- maybe it did satisfy a rule, load more rules
    full = true
    dofile("/lib/core/full_vt.lua")
    return vt100.parse(window)
  end

  if not any_valid then
    -- malformed
    window.output_buffer = window.output_buffer:sub(2)
    return "\27"
  end

  -- else, still consuming
end

return vt100
