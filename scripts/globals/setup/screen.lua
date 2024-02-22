-- 游戏初始化
Game():onEvent(event.type.game.init, function()
    
    screen.max[FrameBarStateClass] = 30
    screen.max[FrameBalloonClass] = BJ_MAX_PLAYERS
    screen.max[FrameToastClass] = 20
    
    if (true == _hideInterface) then
        japi.FrameHideInterface()
        japi.FrameEditBlackBorders(0, 0)
    end
    --- UI -吐司提示
    for i = 0, screen.max[FrameToastClass] do
        UIToast(i)
    end
    --- UI - 血条
    for i = 1, screen.max[FrameBarStateClass] do
        UIBarState(i)
    end
    --- UI - 气泡
    for i = 0, screen.max[FrameBalloonClass] do
        UIBalloon(i)
    end
    --
    sync.receive("BALLOON", function(syncData)
        local uid = syncData.transferData[1]
        local mid = syncData.transferData[2]
        local contentIndex = tonumber(syncData.transferData[3])
        -----@type Unit
        local lighter = i2o(uid)
        -----@type Unit|Effect
        local balloonObj = i2o(mid)
        if (isClass(lighter, UnitClass) == false) then
            return
        end
        if (isMeta(balloonObj, CoordinateMeta) == false) then
            return
        end
        if (inClass(balloonObj, UnitClass, EffectClass) == false) then
            return
        end
        if (lighter:isInterrupt()) then
            return
        end
        -----@type Array
        local balloonConf = balloonObj:balloon()
        if (type(balloonConf) == "table" and type(balloonConf.message) == "table") then
            if (type(balloonConf.message[contentIndex]) == "table") then
                local call = balloonConf.message[contentIndex].call
                if (type(call) == "function") then
                    call({ triggerUnit = lighter, balloonObj = balloonObj })
                end
            end
        end
    end)
end)