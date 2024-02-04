---@param abData noteOnAbilityGetData
TPL_ABILITY.DEMO = AbilityTpl()
    :name("剑之勇气")
    :description(
    {
        "越战越勇，每减少10%的HP则会增加10点攻击力",
        "效果最多叠加9层，最大90点攻击力",
    })
    :targetType(ability.targetType.pas)
    :icon("ReplaceableTextures\\CommandButtons\\BTNArcaniteMelee.blp")
    :onEvent(event.type.ability.get,
    function(abData)
        local ak = abData.triggerAbility:id()
        ---@param propChangeData noteOnObjectChange
        abData.triggerUnit:onEvent(event.type.object.change, ak, function(propChangeData)
            if (propChangeData.key == "hpCur") then
                local u = propChangeData.triggerUnit
                u:buffClear({ key = "剑之勇气" .. ak })
                local cur = propChangeData.new
                if (cur > 0) then
                    local hp = u:hp()
                    local n = math.floor((hp - cur) / hp * 10)
                    if (n > 0) then
                        local atk = 10 * n
                        ---@param buffObj Unit
                        u:buff("剑之勇气" .. ak)
                         :name("剑之勇气")
                         :signal(BUFF_SIGNAL.up)
                         :icon("ReplaceableTextures\\CommandButtons\\BTNArcaniteMelee.blp")
                         :text(colour.hex(colour.gold, n))
                         :description({
                            colour.hex(colour.gold, n .. "层") .. "剑之勇气",
                            colour.hex(colour.lawngreen, "攻击：+" .. atk),
                        })
                         :duration(-1)
                         :purpose(function(buffObj)
                            buffObj:attack("+=" .. atk)
                            buffObj:attach("SmallBuildingFire0", "origin")
                        end)
                         :rollback(function(buffObj)
                            buffObj:attack("-=" .. atk)
                            buffObj:detach("SmallBuildingFire0", "origin")
                        end)
                         :run()
                    end
                end
            end
        end)
    end)
    :onEvent(event.type.ability.lose,
    function(abData)
        local ak = abData.triggerAbility:id()
        abData.triggerUnit:onEvent(event.type.object.change, ak, nil)
        abData.triggerUnit:buffClear({ key = "剑之勇气" .. ak })
    end)