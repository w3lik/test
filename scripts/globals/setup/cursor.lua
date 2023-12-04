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
    local csArea1 = Image("Framework\\ui\\nil.tga", 16, 16):show(false)
    local csFollow = FrameBackdrop("myFollow", FrameGameUI):show(false)

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
        start = function(data)
            local ab = data.ability
            if (true == checkAbility(ab)) then
                audio(Vcm("war3_MouseClick1"))
                sync.send("G_GAME_SYNC", { "ability_effective", ab:id() })
            end
        end,
    })

    cs:setQuote(ABILITY_TARGET_TYPE.tag_unit, {
        start = function(data)
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
        ---@param evtData noteOnMouseEventMoveData
        refresh = function(data, evtData)
            local p, rx, ry = evtData.triggerPlayer, evtData.rx, evtData.ry
            local conf = self:texture()
            local drx = japi.FrameDisAdaptive(rx)
            local _texture, _alpha, _width, _height, _align
            local _isFlashing = false
            ---@type Ability
            local ab = data.ability
            if (isClass(ab, AbilityClass) == false) then
                cs:quoteClear()
                return
            end
            if (ab:isProhibiting() or ab:coolDownRemain() > 0 or isClass(ab:bindUnit(), UnitClass) == false) then
                cs:quoteClear()
                return
            end
            local iss = mouse.isSafety(rx, ry)
            if (iss ~= true) then
                csArea1:position(0, 0)
                csArea1:show(false)
                return
            end
            ---@type Unit|Item
            local under = h2o(japi.GetUnitUnderMouse())
            local hasArrow = (type(conf.arrow) == "table")
            local arrowTexture
            if (hasArrow) then
                arrowTexture = conf.arrow.normal
            end
            if (false == inClass(under, UnitClass, ItemClass)) then
                under = nil
            else
                if (false == under:isAlive()) then
                    under = nil
                elseif (hasArrow) then
                    if (under:isEnemy(p)) then
                        arrowTexture = conf.arrow.negative
                        _isFlashing = true
                    else
                        arrowTexture = conf.arrow.positive
                    end
                end
            end
            local _widthArrow
            local _heightArrow
            if (hasArrow) then
                _widthArrow = conf.arrow.width
                _heightArrow = conf.arrow.height
                local adx = 0.8 - japi.FrameAdaptive(conf.arrow.width)
                local rmp = 1
                if (rx > adx) then
                    local rxp = (conf.arrow.width - (rx - adx)) / conf.arrow.width
                    rmp = math.min(rmp, rxp)
                end
                if (ry < conf.arrow.height) then
                    local ryp = (conf.arrow.height - (conf.arrow.height - ry)) / conf.arrow.height
                    rmp = math.min(rmp, ryp)
                end
                _widthArrow = _widthArrow * rmp
                _heightArrow = _heightArrow * rmp
            end
            local bu = ab:bindUnit()
            local isBan = bu:isInterrupt() or bu:isPause() or bu:isAbilityChantCasting() or bu:isAbilityKeepCasting()
            _alpha = conf.aim.alpha
            _texture = conf.aim.normal
            _width = conf.aim.width
            _height = conf.aim.height
            _align = FRAME_ALIGN_CENTER
            if (isBan) then
                _alpha = math.ceil(_alpha / 2)
            end
            local curAimClosest = self:prop("curAimClosest")
            if (isClass(curAimClosest, UnitClass) and curAimClosest ~= under) then
                J.SetUnitVertexColor(curAimClosest:handle(), table.unpack(curAimClosest:rgba()))
            end
            if (isClass(under, UnitClass)) then
                local red = 255
                local green = 255
                local blue = 255
                if (under:owner():isNeutral()) then
                    green = 230
                    blue = 0
                    _texture = conf.aim.neutral
                elseif (under:isEnemy(p)) then
                    green = 0
                    blue = 0
                    _texture = conf.aim.negative
                elseif (under:isAlly(p)) then
                    red = 127
                    blue = 0
                    _texture = conf.aim.positive
                end
                if ((red ~= 255 or green ~= 255 or blue ~= 255)) then
                    J.SetUnitVertexColor(under:handle(), red, green, blue, under:rgba()[4] or 255)
                end
                self:prop("curAimClosest", under)
            end
            -- 修改处理
            if (_texture == nil) then
                _texture = "Framework\\ui\\nil.tga"
            end
            csPointer:texture(_texture)
            local csfi = 10
            local half = math.ceil((_alpha or 255) / 3)
            local csf = self:prop("csFlashing") or 0
            if (_isFlashing) then
                local cst = self:prop("csFlashTo") or false
                if (cst ~= true) then
                    csf = csf + csfi
                    if (csf >= 0) then
                        csf = 0
                        self:prop("csFlashTo", true)
                    end
                else
                    csf = csf - csfi
                    if (csf < -half) then
                        csf = -half
                        self:prop("csFlashTo", false)
                    end
                end
                self:prop("csFlashing", csf)
            else
                self:clear("csFlashing")
                self:clear("csFlashTo")
            end
            if (_alpha) then
                csPointer:alpha(_alpha + csf)
            end
            if (_width and _height) then
                csPointer:size(_width, _height)
            end
            if (_align) then
                csPointer:relation(_align, FrameGameUI, FRAME_ALIGN_LEFT_BOTTOM, drx, ry)
            end
        end,
        ---@param evtData noteOnMouseEventMoveData
        leftClick = function(data, evtData)
            local ab = data.ability
            if (true == checkAbility(ab)) then
                ---@type Unit
                local targetUnit = Cursor():prop("curAimClosest")
                if (isClass(targetUnit, UnitClass)) then
                    if (ab:isCastTarget(targetUnit) == false) then
                        evtData.triggerPlayer:alert(colour.hex(colour.gold, "目标不允许"))
                    else
                        sync.send("G_GAME_SYNC", { "ability_effective_u", ab:id(), targetUnit:id() })
                    end
                end
            end
        end,
    })

end)