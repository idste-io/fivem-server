-- eonexis-nameplate — client
-- Draws 3D floating names above nearby players using FiveM's native DrawText3d

local function getHPColor(hp)
    if hp > 66 then return 0, 220, 90, 220      -- green
    elseif hp > 33 then return 255, 165, 0, 220  -- orange
    else return 220, 40, 40, 220 end              -- red
end

CreateThread(function()
    while true do
        Wait(0)
        local myPed = PlayerPedId()
        local myPos = GetEntityCoords(myPed)

        for _, pid in ipairs(GetActivePlayers()) do
            if pid == PlayerId() then goto continue end
            local ped = GetPlayerPed(pid)
            if not DoesEntityExist(ped) or IsEntityDead(ped) then goto continue end
            if Config.HideInVehicle and GetVehiclePedIsIn(ped, false) ~= 0 then goto continue end

            local pos = GetEntityCoords(ped)
            local dist = #(myPos - pos)
            if dist > Config.DrawDistance then goto continue end

            -- Fade alpha with distance
            local alpha = math.max(50, 255 - math.floor((dist / Config.DrawDistance) * 200))
            local boneIdx = GetEntityBoneIndexByName(ped, 'SKEL_Head')
            local headPos = boneIdx ~= -1 and GetWorldPositionOfEntityBone(ped, boneIdx) or pos
            local drawPos = vector3(headPos.x, headPos.y, headPos.z + Config.NameHeight)

            -- Player name
            local name = GetPlayerName(pid)
            SetTextScale(0.35, 0.35)
            SetTextFont(4)
            SetTextColour(255, 255, 255, alpha)
            SetTextOutline()
            SetTextCentre(true)
            SetDrawOrigin(drawPos.x, drawPos.y, drawPos.z, 0)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(name)
            EndTextCommandDisplayText(0.0, 0.0)
            ClearDrawOrigin()

            -- HP bar
            if Config.ShowHealthBar then
                local hp = math.max(0, math.floor(((GetEntityHealth(ped) - 100) / 100) * 100))
                local barW = 0.04
                local barH = 0.004
                local r, g, b, a = getHPColor(hp)
                local fillW = barW * (hp / 100)
                local barPos = vector3(drawPos.x, drawPos.y, drawPos.z - 0.07)
                SetDrawOrigin(barPos.x, barPos.y, barPos.z, 0)
                -- background
                DrawRect(0.0, 0.0, barW, barH, 0, 0, 0, 160)
                -- fill
                DrawRect(-(barW / 2) + (fillW / 2), 0.0, fillW, barH, r, g, b, a)
                ClearDrawOrigin()
            end

            ::continue::
        end
    end
end)
