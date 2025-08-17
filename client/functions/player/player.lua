-- Client-side player functions wrapper
-- Fournit des wrappers asynchrones vers les appels server

Shadow.Player = Shadow.Player or {}

-- Génère un id local temporaire pour suivre les callbacks
local __cb_counter = 0
local __callbacks = {}

local function __registerCallback(cb)
    __cb_counter = __cb_counter + 1
    local id = tostring(__cb_counter)
    __callbacks[id] = cb
    return id
end

-- Handler global pour les réponses serveur
RegisterNetEvent("shadow:player:response")
AddEventHandler("shadow:player:response", function(action, cbid, ok, payload)
    local cb = __callbacks[cbid]
    if cb then
        pcall(cb, ok, payload)
        __callbacks[cbid] = nil
    end
end)

-- Récupère l'identité côté serveur
-- cb(expected: identity table or nil)
Shadow.Player.GetIdentity = function(cb)
    local cbid = __registerCallback(function(ok, payload)
        if ok == false then
            -- payload peut être un message d'erreur ou nil
            if cb then cb(nil) end
            return
        end
        if cb then cb(payload) end
    end)
    TriggerServerEvent("shadow:player:getIdentity", cbid)
end

-- Supprime l'identité côté serveur
-- cb(expected: success(bool), affectedRows_or_err)
Shadow.Player.RemoveIdentity = function(cb)
    local cbid = __registerCallback(function(ok, payload)
        if cb then cb(ok, payload) end
    end)
    TriggerServerEvent("shadow:player:removeIdentity", cbid)
end

-- Définit/crée l'identité côté serveur
-- identity: table
-- cb(expected: success(bool), affectedRows_or_err)
Shadow.Player.SetIdentity = function(identity, cb)
    local cbid = __registerCallback(function(ok, payload)
        if cb then cb(ok, payload) end
    end)
    TriggerServerEvent("shadow:player:setIdentity", cbid, identity)
end

-- Export pour le core client
exports("GetPlayer", function()
    return Shadow.Player
end)
