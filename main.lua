-- main.lua  ·  keeps your old UI, adds multi-rig & buy-rig
local G   = require("game")
local Rig = require("player")

-- store & current selection --------------------------------------------
local rigs   = {}         -- list of Rig objects
local selIdx = 1          -- currently selected rig (1-based)

------------------------------------------------------------------ UI helpers
local function drawButton(txt,x,y,w,h)
  w,h = w or G.BTN_W, h or G.BTN_H
  love.graphics.rectangle("line", x, y, w, h)
  love.graphics.printf(txt, x, y + h/2 - 10, w, "center")
end
local function hit(mx,my,x,y,w,h)
  w,h = w or G.BTN_W, h or G.BTN_H
  return mx>x and mx<x+w and my>y and my<y+h
end

------------------------------------------------------------------ save/load
local SAVE = "multirig.dat"
local function saveGame()
  local f = love.filesystem.newFile(SAVE,"w"); if not f then return end
  f:write(G.wallet.."\n")
  f:write(#rigs.."\n")
  for _,r in ipairs(rigs) do f:write(r:serialize().."\n") end
  f:write(os.time().."\n")
  f:close()
end
local function loadGame()
  if not love.filesystem.getInfo(SAVE) then
    rigs[1] = Rig.new(); return
  end
  local lines = {}
  for l in love.filesystem.lines(SAVE) do lines[#lines+1]=l end
  G.wallet = tonumber(lines[1]) or 0
  local n  = tonumber(lines[2]) or 1
  rigs = {}
  for i=1,n do rigs[i] = Rig.deserialize(lines[2+i] or "") end
  -- offline gain (simple, no crit)
  local last = tonumber(lines[#lines]) or os.time()
  local dt   = math.max(0, os.time() - last)
  for _,r in ipairs(rigs) do
    local ticks = math.floor(dt / r:speed())
    G.wallet = G.wallet + ticks * r:yield()
  end
end

------------------------------------------------------------------ LOVE callbacks
function love.load()
  love.window.setTitle("BTC Miner Prototype")
  love.window.setMode(720, 560, {resizable=false})
  love.graphics.setFont(love.graphics.newFont(16))
  loadGame()
end

function love.update(dt)
  for _,r in ipairs(rigs) do r:update(dt) end
end

function love.draw()
  -------------------- LEFT COLUMN (wallet + rigs) ---------------------
  local y = G.TOP_Y
  love.graphics.print(("BTC: %.1f"):format(G.wallet), G.STAT_X, y); y = y + G.LINE_H
  -- show each rig in its own block (CPU/GPU/RAM/Yield/Speed/Crit)
  for i, r in ipairs(rigs) do
    local tag = (i==selIdx) and "► " or "  "
    love.graphics.print(tag.."Rig "..i, G.STAT_X, y);               y = y + G.LINE_H
    love.graphics.print(" CPU  "..Rig.CPU[r.cpu].name,  G.STAT_X+15, y); y=y+G.LINE_H
    love.graphics.print(" GPU  "..Rig.GPU[r.gpu].name,  G.STAT_X+15, y); y=y+G.LINE_H
    love.graphics.print(" RAM  "..Rig.RAM[r.ram].name,  G.STAT_X+15, y); y=y+G.LINE_H
    love.graphics.print(
        string.format(" Yield %.1f/s   Speed %.1fs   Crit %.0f%%",
          r:yield(), r:speed(), r:crit()*100),
        G.STAT_X+15, y); y = y + G.LINE_H + 6
  end

  -------------------- RIGHT COLUMN (upgrade buttons) ------------------
  local r   = rigs[selIdx]
  local bx  = G.SHOP_X
  local by  = G.TOP_Y
  drawButton("CPU "..r:label(Rig.CPU, r.cpu), bx, by)
  by = by + G.BTN_H + G.BTN_SP
  drawButton("GPU "..r:label(Rig.GPU, r.gpu), bx, by)
  by = by + G.BTN_H + G.BTN_SP
  drawButton("RAM "..r:label(Rig.RAM, r.ram), bx, by)
  by = by + G.BTN_H + G.BTN_SP * 2
  drawButton("BUY NEW RIG ("..G.NEW_RIG_COST.." BTC)", bx, by, G.BTN_W, 48)
  by = by + 48 + G.BTN_SP
  drawButton("RESET GAME", bx, by, G.BTN_W, 48)

  -------------------- footer hint -------------------------------------
  love.graphics.print("Number keys 1-4 to select rig",
                      G.STAT_X, 525)
end

------------------------------------------------------------------ INPUT
function love.mousepressed(x,y,b)
  if b~=1 then return end
  local bx, by = G.SHOP_X, G.TOP_Y
  local r = rigs[selIdx]
  if hit(x,y,bx,by) then r:upgradeCPU(); return end
  by = by + G.BTN_H + G.BTN_SP
  if hit(x,y,bx,by) then r:upgradeGPU(); return end
  by = by + G.BTN_H + G.BTN_SP
  if hit(x,y,bx,by) then r:upgradeRAM(); return end
  by = by + G.BTN_H + G.BTN_SP * 2
  if hit(x,y,bx,by,G.BTN_W,48) and G.wallet >= G.NEW_RIG_COST then
    G.wallet = G.wallet - G.NEW_RIG_COST
    rigs[#rigs+1] = Rig.new()
    selIdx = #rigs
    return
  end
  by = by + 48 + G.BTN_SP
  if hit(x,y,bx,by,G.BTN_W,48) then
    -- reset: wipe file & restart with one rig
    love.filesystem.remove(SAVE)
    G.wallet, rigs, selIdx = 0, {Rig.new()}, 1
  end
end

function love.keypressed(k)
  if k == "a" then
    G.wallet = G.wallet + 100               -- cheat
  elseif k:match("%d") then
    local n = tonumber(k)
    if n>=1 and n<=#rigs then selIdx = n end
  end
end

function love.quit() saveGame() end
