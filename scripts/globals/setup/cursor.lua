Game():onEvent(EVENT.Game.Start, "myCursor", function()

    -- 自定义选择圈
    J.EnableSelect(true, false)
    local sel = Image("ReplaceableTextures\\Selection\\SelectionCircleLarge.blp", 72, 72)
    sel:show(false)
    japi.Refresh("mySelection", function()
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
    --- 鼠标指向浮动信息面板
    ---@param instantData noteOnMouseEventMoveData
    japi.MouseSetEvent("move", "myTooltips", function(instantData)
        local tt = self:tooltips()
        if (type(tt) == "function") then
            local p, rx, ry = instantData.triggerPlayer, instantData.rx, instantData.ry
            local drx = japi.FrameDisAdaptive(rx)
            local under = h2o(japi.GetUnitUnderMouse())
            local tx, ty = drx, ry + 0.024
            if (under ~= nil and under:owner() ~= p and false == under:isEnemy(p)) then
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
                        :relation(FRAME_ALIGN_BOTTOM, FrameGameUI, FRAME_ALIGN_LEFT_BOTTOM, tx, ty)
                        :content({ tips = table.concat(tips, '|n') })
                        :show(true)
            else
                FrameTooltips(0):show(false)
            end
        end
    end)

    -- 指针配置
    local cs = Cursor()
    local csPointer = FrameBackdrop("myPointer", FrameGameUI):adaptive(true):size(0.01, 0.01)
    local csArea = Image("Framework\\ui\\nil.tga", 16, 16):show(false)
    local csFollow = FrameBackdrop("myFollow", FrameGameUI):show(false)
    -- 区域贴图尺寸变化量，方形时以高为1做比例替换，小于等于0即瞬间变化完成
    local csSizeRate = 0
    -- 配置各种指针贴图【Framework已准备一些基本图】
    -- 贴图可拉取assets的资源引用【如 assets.uikit("kitName","texture","tga")】
    -- 【arrow中心箭头】一般准备3个贴图：常规、友军、敌军（常见：白、绿、红）
    -- 【aim瞄准准星】一般准备4个贴图：常规、友军、敌军、中立（常见：白、绿、红、金）
    -- 【drag拖拽准星】一般准备1个贴图：常规（常见：灰）
    -- 【circle圆形选区】一般准备2个贴图：友军、敌军（常见：白、红）当为nil时采用魔兽原生4族
    -- 【square方形选区】一般准备2个贴图：友军、敌军（常见：白、红）当为nil时采用魔兽原生建造贴图
    local csTexture = {
        pointer = {
            alpha = 255,
            width = 0,
            height = 0,
            normal = nil,
            ally = nil,
            enemy = nil,
        },
        drag = {
            alpha = 255,
            width = 0.04,
            height = 0.04,
            normal = "Framework\\ui\\cursorDrag.tga"
        },
        aim = {
            alpha = 255,
            width = 0.035,
            height = 0.035,
            normal = "Framework\\ui\\cursorAimWhite.tga",
            ally = "Framework\\ui\\cursorAimGreen.tga",
            enemy = "Framework\\ui\\cursorAimRed.tga",
            neutral = "Framework\\ui\\cursorAimGold.tga",
        },
        circle = {

        },
        square = {
            alpha = 150,
            enable = TEAM_COLOR_BLP_LIGHT_BLUE,
            disable = TEAM_COLOR_BLP_RED,
        },
    }

    -- 设定一些值供临时使用
    local _int1, _bool1, _timer1
    local _unitU, _unit1

    ---@param ab Ability
    ---@return boolean
    local abilityCheck = function(ab)
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
    ---@param ab Ability
    ---@return boolean
    local abilityStart = function(ab)
        if (isClass(_timer1, TimerClass)) then
            destroy(_timer1)
            _timer1 = nil
        end
        J.EnableSelect(false, false)
        time.setTimeout(0, function()
            J.SelectUnit(selection:handle(), true)
        end)
        return abilityCheck(ab)
    end
    local abilityOver = function()
        _timer1 = time.setTimeout(1, function()
            J.EnableSelect(true, false)
        end)
        cs:quote("pointer") -- 切回默认指针
    end

    -- 自定义默认指针逻辑
    cs:setQuote("pointer", {
        start = function()
            _int1 = 0
            _bool1 = false
        end,
        refresh = function(_, evtData)
            local p, rx, ry = evtData.triggerPlayer, evtData.rx, evtData.ry
            if (rx < 0.004 or rx > 0.796 or ry < 0.004 or ry >= 0.596) then
                csPointer:alpha(0)
                return
            end
            local drx = japi.FrameDisAdaptive(rx)
            -- 压缩比例计算
            local adx = 0.8 - japi.FrameAdaptive(csTexture.pointer.width)
            local rmp = 1
            if (rx > adx) then
                local rxp = (csTexture.pointer.width - (rx - adx)) / csTexture.pointer.width
                rmp = math.min(rmp, rxp)
            end
            if (ry < csTexture.pointer.height) then
                local ryp = (csTexture.pointer.height - (csTexture.pointer.height - ry)) / csTexture.pointer.height
                rmp = math.min(rmp, ryp)
            end
            --
            local align = FRAME_ALIGN_LEFT_TOP
            local texture = csTexture.pointer.normal
            local alpha = csTexture.pointer.alpha
            local width = csTexture.pointer.width * rmp
            local height = csTexture.pointer.height * rmp
            local isFleshing = false
            --
            ---@type Unit|Item
            local under = h2o(japi.GetUnitUnderMouse())
            if (inClass(under, UnitClass, ItemClass) and under:isAlive()) then
                if (under:isEnemy(p)) then
                    texture = csTexture.pointer.enemy
                    isFleshing = true
                else
                    texture = csTexture.pointer.ally
                end
            end

            local ci = 10
            local half = math.ceil((alpha or 255) / 3)
            local cn = _int1
            if (isFleshing) then
                if (_bool1 ~= true) then
                    cn = cn + ci
                    if (cn >= 0) then
                        cn = 0
                        _bool1 = true
                    end
                else
                    cn = cn - ci
                    if (cn < -half) then
                        cn = -half
                        _bool1 = false
                    end
                end
                _int1 = cn
            else
                _int1 = 0
                _bool1 = false
            end
            csPointer:texture(texture)
            csPointer:alpha(alpha + cn)
            csPointer:size(width, height)
            csPointer:relation(align, FrameGameUI, FRAME_ALIGN_LEFT_BOTTOM, drx, ry)
        end
    })
    cs:quote("pointer") -- 默认指针默认启动

    cs:setQuote(ABILITY_TARGET_TYPE.tag_nil, {
        start = function(data)
            local ab = data.ability
            if (true == abilityCheck(ab)) then
                audio(Vcm("war3_MouseClick1"))
                sync.send("G_GAME_SYNC", { "ability_effective", ab:id() })
            end
            return false
        end,
    })

    cs:setQuote(ABILITY_TARGET_TYPE.tag_unit, {
        start = function(data)
            local ab = data.ability
            if (true == abilityStart(ab)) then
                audio(Vcm("war3_MouseClick1"))
                -- 双击对己释放
                local u = ab:bindUnit()
                if (ab:isCastTarget(u)) then
                    if (_unitU == u) then
                        _unitU = nil
                        sync.send("G_GAME_SYNC", { "ability_effective_u", ab:id(), u:id() })
                        return false
                    end
                end
            end
            _unit1 = nil
        end,
        over = function()
            abilityOver()
            if (isClass(_unit1, UnitClass)) then
                J.SetUnitVertexColor(_unit1:handle(), table.unpack(_unit1:rgba()))
            end
            _unitU = nil
        end,
        ---@param evtData noteOnMouseEventMoveData
        refresh = function(data, evtData)
            ---@type Ability
            local ab = data.ability
            if (isClass(ab, AbilityClass) == false) then
                cs:quoteClear()
                return
            end
            ---@type Unit
            local bu = ab:bindUnit()
            if (ab:isProhibiting() or ab:coolDownRemain() > 0 or isClass(bu, UnitClass) == false) then
                cs:quoteClear()
                return
            end
            local p, rx, ry = evtData.triggerPlayer, evtData.rx, evtData.ry
            if (rx < 0.004 or rx > 0.796 or ry < 0.004 or ry >= 0.596) then
                csPointer:alpha(0)
                return
            end
            local align = FRAME_ALIGN_CENTER
            local alpha = csTexture.aim.alpha
            local texture = csTexture.aim.normal
            local width = csTexture.aim.width
            local height = csTexture.aim.height
            ---@type Unit|Item
            local under = h2o(japi.GetUnitUnderMouse())
            ---@type Unit
            local isBan = bu:isInterrupt() or bu:isPause() or bu:isAbilityChantCasting() or bu:isAbilityKeepCasting()
            if (isBan) then
                alpha = math.ceil(alpha / 2)
            end
            local closest = _unit1
            if (isClass(closest, UnitClass) and closest ~= under) then
                J.SetUnitVertexColor(closest:handle(), table.unpack(closest:rgba()))
            end
            if (isClass(under, UnitClass)) then
                local red = 255
                local green = 255
                local blue = 255
                if (under:owner():isNeutral()) then
                    green = 230
                    blue = 0
                    texture = csTexture.aim.neutral
                elseif (under:isEnemy(p)) then
                    green = 0
                    blue = 0
                    texture = csTexture.aim.enemy
                elseif (under:isAlly(p)) then
                    red = 127
                    blue = 0
                    texture = csTexture.aim.ally
                end
                if ((red ~= 255 or green ~= 255 or blue ~= 255)) then
                    J.SetUnitVertexColor(under:handle(), red, green, blue, under:rgba()[4] or 255)
                end
                _unit1 = under
            end
            csPointer:texture(texture)
            csPointer:alpha(alpha)
            csPointer:size(width, height)
            csPointer:relation(align, FrameGameUI, FRAME_ALIGN_LEFT_BOTTOM, rx, ry)
        end,
        ---@param evtData noteOnMouseEventMoveData
        leftClick = function(data, evtData)
            local ab = data.ability
            ---@type Unit
            local targetUnit = _unit1
            if (isClass(targetUnit, UnitClass)) then
                if (ab:isCastTarget(targetUnit) == false) then
                    evtData.triggerPlayer:alert(colour.hex(colour.gold, "目标不允许"))
                else
                    sync.send("G_GAME_SYNC", { "ability_effective_u", ab:id(), targetUnit:id() })
                end
            end
        end,
    })

    cs:setQuote(ABILITY_TARGET_TYPE.tag_loc, {
        start = function(data)
            local ab = data.ability
            if (true == abilityStart(ab)) then
                audio(Vcm("war3_MouseClick1"))
            end
        end,
        over = function()
            abilityOver()
        end,
        ---@param evtData noteOnMouseEventMoveData
        refresh = function(data, evtData)
            ---@type Ability
            local ab = data.ability
            if (isClass(ab, AbilityClass) == false) then
                cs:quoteClear()
                return
            end
            ---@type Unit
            local bu = ab:bindUnit()
            if (ab:isProhibiting() or ab:coolDownRemain() > 0 or isClass(bu, UnitClass) == false) then
                cs:quoteClear()
                return
            end
            local rx, ry = evtData.rx, evtData.ry
            if (rx < 0.004 or rx > 0.796 or ry < 0.004 or ry >= 0.596) then
                csPointer:alpha(0)
                return
            end
            local align = FRAME_ALIGN_CENTER
            local alpha = csTexture.aim.alpha
            local texture = csTexture.aim.normal
            local width = csTexture.aim.width
            local height = csTexture.aim.height
            local isBan = bu:isInterrupt() or bu:isPause() or bu:isAbilityChantCasting() or bu:isAbilityKeepCasting()
            if (isBan) then
                alpha = math.ceil(alpha / 2)
            end
            csPointer:texture(texture)
            csPointer:alpha(alpha)
            csPointer:size(width, height)
            csPointer:relation(align, FrameGameUI, FRAME_ALIGN_LEFT_BOTTOM, rx, ry)
        end,
        ---@param evtData noteOnMouseEventMoveData
        leftClick = function(data, evtData)
            local ab = data.ability
            if (true ~= mouse.isSafety()) then
                return
            end
            local cond = {
                x = japi.GetMouseTerrainX(),
                y = japi.GetMouseTerrainY(),
            }
            if (ab:isBanCursor(cond)) then
                evtData.triggerPlayer:alert(colour.hex(colour.red, "无效目标"))
                return
            end
            sync.send("G_GAME_SYNC", { "ability_effective_xyz", ab:id(), cond.x, cond.y, japi.GetMouseTerrainZ() })
        end,
    })

    cs:setQuote(ABILITY_TARGET_TYPE.tag_circle, {
        start = function(data)
            local ab = data.ability
            if (true == abilityStart(ab)) then
                audio(Vcm("war3_MouseClick1"))
            end
            _int1 = -1
            _unit1 = nil
        end,
        over = function()
            abilityOver()
            if (type(_unit1) == "table") then
                for _, u in ipairs(_unit1) do
                    J.SetUnitVertexColor(u:handle(), table.unpack(u:rgba()))
                end
            end
            _unit1 = nil
        end,
        ---@param evtData noteOnMouseEventMoveData
        refresh = function(data, evtData)
            ---@type Ability
            local ab = data.ability
            if (isClass(ab, AbilityClass) == false) then
                cs:quoteClear()
                return
            end
            ---@type Unit
            local bu = ab:bindUnit()
            if (ab:isProhibiting() or ab:coolDownRemain() > 0 or isClass(bu, UnitClass) == false) then
                cs:quoteClear()
                return
            end
            local p, rx, ry = evtData.triggerPlayer, evtData.rx, evtData.ry
            if (true ~= mouse.isSafety(rx, ry)) then
                csArea:show(false)
                return
            end
            local castRadius = ab:castRadius()
            local circleParams = csTexture.circle
            if (circleParams == nil) then
                local skin = p:skin()
                if (skin ~= RACE_HUMAN_NAME and skin ~= RACE_ORC_NAME and skin ~= RACE_NIGHTELF_NAME and skin ~= RACE_UNDEAD_NAME) then
                    skin = p:race()
                end
                if (RACE_SELECTION_SPELL_AREA_OF_EFFECT[skin]) then
                    circleParams = {
                        alpha = 255,
                        enable = RACE_SELECTION_SPELL_AREA_OF_EFFECT[skin],
                        disable = nil,
                    }
                else
                    circleParams = {
                        alpha = 255,
                        enable = "ReplaceableTextures\\Selection\\SpellAreaOfEffect.blp",
                        disable = nil,
                    }
                end
            end
            local curSize = _int1
            if (csSizeRate <= 0 or curSize == castRadius) then
                curSize = castRadius
            elseif (curSize < castRadius) then
                curSize = math.min(castRadius, curSize + csSizeRate)
            elseif (curSize > castRadius) then
                curSize = math.max(castRadius, curSize - csSizeRate)
            end
            _int1 = curSize
            local tx = japi.GetMouseTerrainX()
            local ty = japi.GetMouseTerrainY()
            local prevUnit = _unit1
            local newUnits = Group():catch(UnitClass, {
                limit = 30,
                circle = {
                    x = tx,
                    y = ty,
                    radius = castRadius,
                },
                ---@param enumUnit Unit
                filter = function(enumUnit)
                    return ab:isCastTarget(enumUnit)
                end
            })
            local renderAllow = {}
            for _, u in ipairs(newUnits) do
                renderAllow[u:id()] = true
            end
            if (type(prevUnit) == "table") then
                for _, u in ipairs(prevUnit) do
                    if (renderAllow[u:id()] == nil) then
                        J.SetUnitVertexColor(u:handle(), table.unpack(u:rgba()))
                    end
                end
            end
            local texture
            if (ab:isBanCursor({ x = tx, y = ty, radius = curSize, units = newUnits })) then
                texture = circleParams.disable or circleParams.enable
            else
                texture = circleParams.enable
            end
            _unit1 = newUnits
            if (#newUnits > 0) then
                for _, ru in ipairs(newUnits) do
                    local red = 255
                    local green = 255
                    local blue = 255
                    if (ru:owner():isNeutral()) then
                        green = 230
                        blue = 0
                    elseif (ru:isEnemy(p)) then
                        green = 0
                        blue = 0
                    elseif (ru:isAlly(p)) then
                        red = 127
                        blue = 0
                    end
                    if ((red ~= 255 or green ~= 255 or blue ~= 255)) then
                        J.SetUnitVertexColor(ru:handle(), red, green, blue, ru:rgba()[4] or 255)
                    end
                end
                newUnits = nil
            end
            csArea:rgba(255, 255, 255, circleParams.alpha)
            csArea:texture(texture)
            csArea:size(curSize * 2, curSize * 2)
            csArea:position(tx, ty)
            csArea:show(true)
        end,
        ---@param evtData noteOnMouseEventMoveData
        leftClick = function(data, evtData)
            local ab = data.ability
            if (true ~= mouse.isSafety()) then
                return
            end
            local cond = {
                x = japi.GetMouseTerrainX(),
                y = japi.GetMouseTerrainY(),
                radius = obj:prop("curSize") or ab:castRadius(),
                units = _unit1,
            }
            if (ab:isBanCursor(cond)) then
                evtData.triggerPlayer:alert(colour.hex(colour.red, "无效范围"))
                return
            end
            sync.send("G_GAME_SYNC", { "ability_effective_xyz", ab:id(), cond.x, cond.y, japi.GetMouseTerrainZ() })
        end,
    })

end)