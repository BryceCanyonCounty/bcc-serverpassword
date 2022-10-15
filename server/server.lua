local players = {}

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
        print("ERROR: Failed to create bccpassword Table")
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

local function KickPlayer(_src, kicks, steamid, lang) 
    DropPlayer(_src, lang)
    kicks = kicks + 1


    local timeout = os.time() + (ServerConfig.TimeoutMinutes * 60)

    exports.ghmattimysql:executeSync("UPDATE bccpassword SET `kicks` = ?, `timeout` = ? WHERE `cname` = ?", {kicks, timeout, steamid })
end

local function initiate(_src)
    local running = true
    local kicktime = ServerConfig.TimeToKick
    local current = 0
    local s = tonumber(_src)
    local steamid = GetSteamID(_src)

    local curplayer = exports.ghmattimysql:executeSync( "SELECT * FROM bccpassword WHERE cname=@id;", {['@id'] = steamid})
    local kicks = 0
    if curplayer[1] then
        kicks = curplayer[1].kicks
    else
        exports.ghmattimysql:executeSync("INSERT INTO bccpassword (cname, kicks) VALUES (@cname, @kicks)", {['@cname'] = steamid, ['@kicks']=0})
    end

    if players[s] == nil then
        players[s] = {
            attempts = 0,
            kicks = kicks,
            passed = false,
            reset = false
        }
    end

    Citizen.CreateThread(function()
        while running do
            Wait(1000)
            current = current + 1        
            
            if kicktime == nil then
                kicktime = 0
            end

            if current >= kicktime then
                KickPlayer(_src, players[s].kicks, steamid, Config.lang.notime)
                running = false
            elseif players[s].reset then
                players[s].reset = false
                current = 0
            elseif players[s].passed then
                running = false
            end
        end
    end)
end

AddEventHandler('playerDropped', function(reason)
    local _src = source
    players[tonumber(_src)].passed = true
end)

RegisterServerEvent('bccac:initiate')
AddEventHandler('bccac:initiate', function()
    local _src = source
    initiate(_src)
end)

RegisterServerEvent('bccac:ispass')
AddEventHandler('bccac:ispass', function(cpass)
    local _src = source
    local s = tonumber(_src)
    local steamid = GetSteamID(_src)

    local curplayer = exports.ghmattimysql:executeSync( "SELECT * FROM bccpassword WHERE cname=@id;", {['@id'] = steamid})
    local kicks = 0
    if curplayer[1] then
        kicks = curplayer[1].kicks
    else
        exports.ghmattimysql:executeSync("INSERT INTO bccpassword (cname, kicks) VALUES (@cname, @kicks)", {['@cname'] = steamid, ['@kicks']=0})
    end

    if players[s] == nil then
        players[s] = {
            attempts = 0,
            kicks = kicks,
            passed = false,
            reset = false
        }
    end

    players[s].kicks = kicks
    players[s].attempts = players[s].attempts + 1
    if cpass == ServerConfig.Password then
        -- The correct password has been entered
        players[s].passed = true
        TriggerClientEvent('bccac:ispass:cr', _src, true, players[s].attempts)
    else
        -- incorrect password has been entered
        if players[s].attempts > ServerConfig.Attempts-1 then
            -- Player has exceeded the allowed attempts. Kick them
            KickPlayer(_src, players[s].kicks, steamid, Config.lang.kick)
        else
            -- User has not hit limit yet, let's let them retry
            players[s].reset = true
            TriggerClientEvent('bccac:ispass:cr', _src, false, players[s].attempts)
        end
    end
end)

AddEventHandler("playerConnecting", function(name, setMessage, deferrals)
    deferrals.defer()
    deferrals.update('checking bans...')
    local _src = source
    local steamid = GetSteamID(_src)
    local s = tonumber(_src)

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

        if kicks >= ServerConfig.KicksToBan then
            deferrals.done(Config.lang.banned)
            CancelEvent()
        elseif timeout ~= nil then
            if tonumber(timeout) > os.time() then
                deferrals.done(Config.lang.timeout)
                CancelEvent()
            else
                deferrals.done()
            end        
        else
            deferrals.done()
        end
    end
end)