-- Omahide binds. From ~/.config/hypr/bindings.lua:
--   dofile(os.getenv("HOME") .. "/.config/omarchy/plugins/omahide/hypr.lua")

o.window({ tag = "omahide" }, { animation = "slide top" })

local hide_stack = {}

local function json_escape(s)
  return tostring(s or ""):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", " ")
end

local function write_hidden()
  local dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
  local f = io.open(dir .. "/omahide.json", "w")
  if not f then
    return
  end
  f:write("[")
  local first = true
  local seen = {}
  for _, w in ipairs(hl.get_windows() or {}) do
    local ws = w.workspace
    local name = ws and tostring(ws.name or "") or ""
    local addr = tostring(w.address or "")
    if name:match("^special:hidden%-") and addr ~= "" and not seen[addr] then
      seen[addr] = true
      if not first then
        f:write(",")
      end
      first = false
      f:write(string.format(
        '{"address":"%s","class":"%s","title":"%s","workspace":"%s"}',
        json_escape(addr),
        json_escape(w.class),
        json_escape(w.title),
        json_escape(name)
      ))
    end
  end
  f:write("]\n")
  f:close()
end

local function window_by_address(addr)
  addr = tostring(addr or "")
  if addr == "" then
    return nil
  end
  return hl.get_window("address:" .. addr)
    or (addr:sub(1, 2) ~= "0x" and hl.get_window("address:0x" .. addr))
    or hl.get_window(addr)
end

local function hide_window(win)
  if not win then
    return false
  end
  local ws = win.workspace
  if not ws or ws.special then
    return false
  end
  local id = ws.id
  hide_stack[#hide_stack + 1] = { address = win.address, workspace = id }
  hl.dispatch(hl.dsp.window.tag({ tag = "+omahide", window = win }))
  hl.dispatch(hl.dsp.window.move({
    window = win,
    workspace = "special:hidden-" .. tostring(id),
    follow = false,
  }))
  write_hidden()
  return true
end

local function restore_window(win, workspace)
  if not win then
    return
  end
  hl.dispatch(hl.dsp.window.move({
    window = win,
    workspace = tostring(workspace),
    follow = true,
  }))
  hl.dispatch(hl.dsp.window.tag({ tag = "-omahide", window = win }))
  hl.dispatch(hl.dsp.focus({ window = win }))
  hl.dispatch(hl.dsp.window.bring_to_top())
  write_hidden()
end

function omahide_restore(addr, workspace)
  restore_window(window_by_address(addr), workspace)
end

local function unhide_last()
  while #hide_stack > 0 do
    local item = table.remove(hide_stack)
    local win = window_by_address(item.address)
    if win then
      restore_window(win, item.workspace)
      return
    end
  end
  local ws = hl.get_active_workspace()
  if not ws or ws.special then
    return
  end
  local wins = hl.get_workspace_windows("special:hidden-" .. tostring(ws.id)) or {}
  if #wins == 0 then
    return
  end
  table.sort(wins, function(a, b)
    return (a.focus_history_id or 0) < (b.focus_history_id or 0)
  end)
  restore_window(wins[1], ws.id)
end

o.bind("SUPER + H", "Hide window", function()
  hide_window(hl.get_active_window())
end)

o.bind("SUPER + SHIFT + H", "Hide other windows", function()
  local active = hl.get_active_window()
  local ws = hl.get_active_workspace()
  if not ws or ws.special then
    return
  end
  local active_addr = active and active.address
  local wins = hl.get_workspace_windows(ws) or {}
  for _, win in ipairs(wins) do
    if win and win.address ~= active_addr then
      hide_window(win)
    end
  end
end)

o.bind("SUPER + ALT + H", "Unhide last window", function()
  unhide_last()
end)

hl.on("window.close", write_hidden)
hl.on("window.destroy", write_hidden)
hl.on("window.move_to_workspace", write_hidden)

write_hidden()
