-- 指针配置
local cs = Cursor()

--- 鼠标指向浮动信息面板
---@param under Unit|Item
---@param x number
---@param y number
cs:tooltips(function(under, x, y)
    if (under ~= nil and under:owner() ~= PlayerLocal() and false == under:isEnemy(PlayerLocal())) then
        local tips = {}
        if (isClass(under, UnitClass)) then
            table.insert(tips, under:name())
            if (under:level() > 0) then
                table.insert(tips, "Lv " .. under:level())
            end
        elseif (isClass(under, ItemClass)) then
            table.insert(tips, under:name())
            if (under:level() > 0) then
                table.insert(tips, "Lv " .. under:level())
            end
        end
        FrameTooltips(0)
                :relation(FRAME_ALIGN_BOTTOM, FrameGameUI, FRAME_ALIGN_LEFT_BOTTOM, x, y)
                :content({ tips = table.concat(tips, '|n') })
                :show(true)
        return
    end
    FrameTooltips(0):show(false)
end)

-- 自定义选择圈
Game():onEvent(EVENT.Game.Start, "likSelection", function()
    J.EnableSelect(true, false)
    local sel = Image("ReplaceableTextures\\Selection\\SelectionCircleLarge.blp", 72, 72)
    sel:show(false)
    japi.Refresh("LIK_CursorSelection", function()
        if (false == japi.IsWindowActive()) then
            return
        end
        local p = PlayerLocal()
        local o = p:selection()
        if ((isClass(o, UnitClass) or isClass(o, ItemClass)) and o:isAlive() and false == o:isLocust()) then
            local s = 72 * o:scale()
            if (s > 0) then
                ---@type Image
                sel:size(s, s)
                sel:position(o:x(), o:y())
                if (o:owner() == p) then
                    sel:rgba(0, 255, 0, 255)
                elseif (o:isEnemy(p)) then
                    sel:rgba(255, 0, 0, 255)
                else
                    sel:rgba(255, 255, 0, 255)
                end
                sel:show(true)
            else
                sel:show(false)
            end
        else
            sel:show(false)
        end
    end)
end)

---@param ab Ability
---@return boolean
local checkAbility = function(ab)
    if (isClass(ab, AbilityClass)) then
        return false
    end
    local p = PlayerLocal()
    local selection = p:selection()
    if (selection == nil or selection:owner():id() ~= p:id()) then
        return false
    end
    if (ab:isProhibiting() == true) then
        p:alert(colour.hex(colour.gold, ab:prohibitReason()))
        return false
    end
    if (selection:isInterrupt() or selection:isPause()) then
        p:alert(colour.hex(colour.red, "无法行动"))
        return false
    end
    if (selection:isAbilityChantCasting() or selection:isAbilityKeepCasting()) then
        p:alert(colour.hex(colour.gold, "施法中"))
        return false
    end
    return true
end

cs:setQuote(ABILITY_TARGET_TYPE.tag_nil, {
    setup = function(data)
        local ab = data.ability
        if (true == checkAbility(ab)) then
            audio(Vcm("war3_MouseClick1"))
            sync.send("G_GAME_SYNC", { "ability_effective", ab:id() })
        end
    end,
})

cs:setQuote(ABILITY_TARGET_TYPE.tag_unit, {
    setup = function(data)
        local ab = data.ability
        if (true == checkAbility(ab)) then
            audio(Vcm("war3_MouseClick1"))
            local u = ab:bindUnit()
            if (ab:isCastTarget(u)) then
                sync.send("G_GAME_SYNC", { "ability_effective_u", ab:id(), ab:bindUnit():id() })
                return
            end
            J.EnableSelect(false, false)
            time.setTimeout(0, function()
                J.SelectUnit(selection:handle(), true)
            end)
        end
    end,
})