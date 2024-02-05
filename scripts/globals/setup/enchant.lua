--- 方便伤害类型引用
---@alias noteDamageTypeData {value:string,label:string}

---@type noteDamageTypeData
injury.damageType.fire = nil
---@type noteDamageTypeData
injury.damageType.rock = nil
---@type noteDamageTypeData
injury.damageType.water = nil
---@type noteDamageTypeData
injury.damageType.ice = nil
---@type noteDamageTypeData
injury.damageType.wind = nil
---@type noteDamageTypeData
injury.damageType.light = nil
---@type noteDamageTypeData
injury.damageType.dark = nil
---@type noteDamageTypeData
injury.damageType.grass = nil
---@type noteDamageTypeData
injury.damageType.thunder = nil
---@type noteDamageTypeData
injury.damageType.poison = nil
---@type noteDamageTypeData
injury.damageType.steel = nil

-- 附魔设定
local fire = Enchant("fire", "火")
fire:setAttachEffect("origin", "BreathOfFireDamage")
Enchant("rock", "岩")
Enchant("water", "水")
Enchant("ice", "冰")
Enchant("wind", "风")
Enchant("light", "光")
Enchant("dark", "暗")
Enchant("grass", "草")
Enchant("thunder", "雷")
Enchant("poison", "毒")
Enchant("steel", "钢")