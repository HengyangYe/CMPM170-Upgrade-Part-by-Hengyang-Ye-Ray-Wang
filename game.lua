-- game.lua  ·  global wallet & tweakables
local G = {}

G.wallet        = 0           -- total BTC shared by all rigs
G.NEW_RIG_COST  = 1000        -- price to buy a brand-new mining rig

-- UI constants (kept from your old layout)
G.STAT_X  , G.SHOP_X  , G.TOP_Y = 40 , 340 , 40
G.LINE_H  = 22
G.BTN_W   , G.BTN_H   , G.BTN_SP = 240 , 56 , 12

return G
