DeferralCards = exports['bcc-deferralcards']
local states = {}

local createTable = function()
    local result = exports.ghmattimysql:executeSync([[
        CREATE TABLE IF NOT EXISTS `bccpassword` (
            `id` INT(20) NOT NULL AUTO_INCREMENT,
            `cname` varchar(255) NOT NULL DEFAULT '0',
            `kicks` int(30) NOT NULL DEFAULT '0',
            `timeout` varchar(255) NOT NULL DEFAULT '0',
            PRIMARY KEY (`id`)
        ) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = DYNAMIC;
    ]])
    if result and result.warningStatus > 1 then
        print("ERROR: Failed to create Table")
    end
end

Citizen.CreateThread(function()
    createTable()
end)


local GetSteamID = function(src)
    local sid = GetPlayerIdentifiers(src)[1] or false

    if (sid == false or sid:sub(1,5) ~= "steam") then
        return false
    end

    return sid
end

function KickPlayer(s) 
    local steamid = GetSteamID(_src)
    local timeout = os.time() + (Config.TimeoutMinutes * 60)
    states[s].kicks = states[s].kicks + 1
    exports.ghmattimysql:executeSync("UPDATE bccpassword SET `kicks` = ?, `timeout` = ? WHERE `cname` = ?", {states[s].kicks, timeout, steamid })
end

function PresentError(s, deferral, cb)
    states[s].current = 'error'

    local card = DeferralCards.Card:Create({
        body = {
            DeferralCards.Container:Create({
                items = {
                    DeferralCards.CardElement:Image({
                        url = 'https://user-images.githubusercontent.com/10902965/191680366-63669ad2-ad7b-4dbe-8e40-b880beeaec5f.png',
                        size = 'large',
                        horizontalAlignment = 'center'
                    }),
                    DeferralCards.CardElement:TextBlock({
                        text = Config.lang.error,
                        weight = 'bold',
                        size = 'large',
                        horizontalAlignment = 'center'
                    }),
                    DeferralCards.Container:ActionSet({
                        actions = {
                            DeferralCards.Action:Submit({
                                id = 'back_button',
                                title = Config.lang.back
                            })
                        }
                    })
                },
                isVisible = true
            })
        }
    })

    deferral.presentCard(card, function(data, rawData)
        if data.submitId == 'back_button' then 
            PresentLogin(s, deferral, cb)
        end
    end)
end

function PresentLogin(s, deferral, cb)
    states[s].current = 'login'

    local card = DeferralCards.Card:Create({
        body = {
            DeferralCards.Container:Create({
                items = {
                    DeferralCards.CardElement:Image({
                        url = Config.logo,
                        size = 'large',
                        horizontalAlignment = 'center'
                    }),
                    DeferralCards.CardElement:TextBlock({
                        text = Config.lang.header,
                        weight = 'Light',
                        size = 'large',
                        horizontalAlignment = 'center'
                    }),
                    DeferralCards.Input:Text({
                        id = 'password',
                        title = '',
                        placeholder = Config.lang.placeholder
                    }),
                    DeferralCards.Container:ActionSet({
                        actions = {
                            DeferralCards.Action:Submit({
                                id = 'submit_join',
                                title = Config.lang.button
                            })
                        }
                    })
                },
                isVisible = true
            })
        }
    })


    deferral.presentCard(card, function(data, rawData)
        if data.submitId == 'submit_join' then 
            if Config.Password == data.password then
                deferral.update(Config.lang.connecting)
                Wait(1000)
                deferral.done()
                cb()
            else         
                states[s].attempts = states[s].attempts + 1
                PresentError(s, deferral, cb)
            end
        end
    end)
end


AddEventHandler('playerConnecting', function(name, skr, deferral)
    deferral.defer()

    local _src = source
    local steamid = GetSteamID(_src)
    local s = tonumber(_src)
    Wait(50)

    if s == nil then
        deferrals.done('Account not found')
        CancelEvent()
    else

        local curplayer = exports.ghmattimysql:executeSync( "SELECT * FROM bccpassword WHERE cname=@id;", {['@id'] = steamid})
        local kicks = 0
        local timeout = nil
        if curplayer[1] then
            kicks = curplayer[1].kicks
            timeout = curplayer[1].timeout
        else
            exports.ghmattimysql:executeSync("INSERT INTO bccpassword (cname, kicks) VALUES (@cname, @kicks)", {['@cname'] = steamid, ['@kicks']=0})
        end

        states[_src] = {
            current = 'login',
            kicks = kicks,
            timeout = timeout,
            attempts = 0
        }

        if kicks >= Config.KicksToBan then
            deferrals.done(Config.lang.banned)
            CancelEvent()
        elseif timeout ~= nil and tonumber(timeout) > os.time() then
            deferrals.done(Config.lang.timeout)
            CancelEvent()      
        else
            CreateThread(function()
                local breakLoop = false
                while true do
                    if states[_src].attempts > Config.Attempts-1 then
                        KickPlayer(_src)
                        deferrals.done(Config.lang.kick)
                        breakLoop = true
                        CancelEvent()
                    else
                        if states[_src].current == 'login' then
                            PresentLogin(_src, deferral, function()
                                breakLoop = true
                            end)
                        else
                            PresentError(_src, deferral, function()
                                breakLoop = true
                            end)
                        end
                    end
    
                    if breakLoop then break end
                    Wait(1000)
                end
            end)
        end
    end
end)
