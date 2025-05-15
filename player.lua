-- rig.lua  ·  one mining rig (CPU / GPU / RAM + timer)
local G = require("game")            -- access global wallet
local Rig = {}
Rig.__index = Rig

-- ── hardware tiers (unchanged names / costs) ──────────────────────────
Rig.CPU = {
  { name="Intel i3-10105F", yield=1,  cost=10  },
  { name="Intel i5-12400",  yield=2,  cost=50  },
  { name="Intel i7-12700K", yield=4,  cost=200 },
  { name="Intel i9-13900K", yield=8,  cost=800 },
}
Rig.GPU = {
  { name="GTX 1060", speed=2.0, cost=15  },
  { name="RTX 2060", speed=1.6, cost=60  },
  { name="RTX 3060", speed=1.2, cost=250 },
  { name="RTX 4070", speed=0.8, cost=1000},
  { name="RTX 5090", speed=0.4, cost=5000},
}
Rig.RAM = {
  { name="8 GB",  crit=0.05, cost=8   },
  { name="16 GB", crit=0.10, cost=40  },
  { name="32 GB", crit=0.20, cost=160 },
  { name="64 GB", crit=0.40, cost=640 },
}

-- ── constructor ───────────────────────────────────────────────────────
function Rig.new()
  return setmetatable({cpu=1, gpu=1, ram=1, timer=0}, Rig)
end

-- derived stats ---------------------------------------------------------
function Rig:yield() return Rig.CPU[self.cpu].yield end
function Rig:speed() return Rig.GPU[self.gpu].speed end
function Rig:crit () return Rig.RAM[self.ram].crit  end

-- label helper (for buttons) -------------------------------------------
function Rig:label(tbl, idx)
  local nxt = tbl[idx+1]
  return nxt and ("> "..nxt.name.." ("..nxt.cost.." BTC)") or "MAX"
end

-- auto-mine: called each frame by main.lua ------------------------------
function Rig:update(dt)
  self.timer = self.timer + dt
  while self.timer >= self:speed() do
    self.timer = self.timer - self:speed()
    local gain = self:yield()
    if love.math.random() < self:crit() then gain = gain * 2 end
    G.wallet  = G.wallet + gain
  end
end

-- generic upgrade helper ------------------------------------------------
local function try(self, tiers, field)
  local nxt = self[field] + 1
  local t   = tiers[nxt]
  if t and G.wallet >= t.cost then
    G.wallet      = G.wallet - t.cost
    self[field]   = nxt
  end
end
function Rig:upgradeCPU() try(self, Rig.CPU, "cpu") end
function Rig:upgradeGPU() try(self, Rig.GPU, "gpu") end
function Rig:upgradeRAM() try(self, Rig.RAM, "ram") end

-- save / load helpers ---------------------------------------------------
function Rig:serialize() return self.cpu..","..self.gpu..","..self.ram end
function Rig.deserialize(line)
  local c,g,r = line:match("([^,]+),([^,]+),([^,]+)")
  local rig = Rig.new()
  rig.cpu, rig.gpu, rig.ram = tonumber(c) or 1, tonumber(g) or 1, tonumber(r) or 1
  return rig
end

return Rig
