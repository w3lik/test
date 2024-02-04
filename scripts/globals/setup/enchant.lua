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
Enchant("fire"):name("火"):attachEffect("origin", "BreathOfFireDamage")
Enchant("rock"):name("岩")
Enchant("water"):name("水")
Enchant("ice"):name("冰")
Enchant("wind"):name("风")
Enchant("light"):name("光")
Enchant("dark"):name("暗")
Enchant("grass"):name("草")
Enchant("thunder"):name("雷")
Enchant("poison"):name("毒")
Enchant("steel"):name("钢")