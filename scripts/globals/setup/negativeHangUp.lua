--- 挂机灭绝器
--- negative hang up
if (false == DEBUGGING) then
    
    Game():onEvent(event.type.game.start, "negativeHangUp", function()
        
        sync.receive("negativeHangUp", function(syncData)
            local idx = tonumber(syncData.transferData[1])
            Player(idx):quit("消极挂机")
        end)
        async.call(PlayerLocal(), function()
            local cx, cy = camera.x(), camera.y()
            local click = false
            local clickResume = function()
                click = true
            end
            mouse.onLeftClick("negativeHangUp", clickResume)
            mouse.onRightClick("negativeHangUp", clickResume)
            time.setInterval(30, function(curTimer)
                local period = curTimer:period()
                if (period > 180) then
                    destroy(curTimer)
                    return
                end
                local cx2, cy2 = camera.x(), camera.y()
                if (click ~= true and cx == cx2 and cy == cy2) then
                    destroy(curTimer)
                    sync.send("negativeHangUp", { PlayerLocal():index() })
                    return
                end
                cx, cy = cx2, cy2
                click = false
                curTimer:setPeriod(period + 10)
            end)
        end)
    
    end)

end