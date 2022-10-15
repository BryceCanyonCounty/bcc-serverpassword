-- Queue all progress tasks to prevent infinite loops and overlap
local state = false

local function ToggleUI()
    state = not state
    SendNUIMessage({
        type = 'toggle',
        visible = state,
        config = Config
    })
    SetNuiFocus(state, state)
end

RegisterNUICallback('updatestate', function(args, nuicb)
    state = args.state
    SetNuiFocus(state, state)
    nuicb('ok')
end)

AddEventHandler('onClientMapStart', function()
    Wait(1000)

    local ped = GetPlayerPed(-1)
    FreezeEntityPosition(ped, true)

    ToggleUI()
    TriggerServerEvent('bccac:initiate')
end)


CreateThread(function()
    while true do
        if state then
            SetNuiFocus(true, true) 
        end
        Wait(5000)
    end
end)

RegisterNUICallback('checkpass', function(args, nuicb)
    TriggerServerEvent('bccac:ispass', args.password)
    nuicb('ok')
end)

RegisterNetEvent('bccac:ispass:cr')
AddEventHandler('bccac:ispass:cr', function(status, attempts)
    if status == true then
        local ped = GetPlayerPed(-1)
        FreezeEntityPosition(ped, false)

        ToggleUI()
    end
	SendNUIMessage({
        type = 'passcr',
        status = status,
        attempts = attempts
    })
end)