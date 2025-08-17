-- Récupération identité du joueur depuis la base de données
-- Now asynchronous: accept a callback (source, cb) -> cb(identity or nil)
Shadow.GetPlayerIdentity = function(source, cb)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then
        if cb then cb(false, "no_identifier") end
        return
    end

    -- Requête suivant le schéma `players`
    Shadow.DB.FetchAll("SELECT identifier, first_name, last_name, dob, sex, job, job_grade, crew, crew_grade, cash, bank, coords, inventory, skin, metadata FROM players WHERE identifier = ? LIMIT 1", {identifier}, function(result)
        local row = result and result[1]
        if not row then
            if cb then cb(nil) end
            return
        end

        local identity = {
            identifier = row.identifier,
            firstname = row.first_name or "",
            lastname = row.last_name or "",
            dob = row.dob and tostring(row.dob) or nil,
            sex = row.sex or nil,
            job = { name = row.job or "citizen", grade = row.job_grade or 0 },
            crew = { name = row.crew or "none", grade = row.crew_grade or 0 },
            cash = tonumber(row.cash) or 0,
            bank = tonumber(row.bank) or 0,
            coords = row.coords or nil,
            inventory = row.inventory or nil,
            skin = row.skin or nil,
            metadata = row.metadata or nil
        }

        if cb then cb(identity) end
    end)
end

-- Helpers de sécurité pour les events
local _action_rate = {} -- identifier -> {count, window_start}
local RATE_WINDOW = 10 -- seconds
local RATE_MAX = 8 -- max actions per window

local function isValidCbid(cbid)
    if not cbid then return false end
    if type(cbid) ~= "string" and type(cbid) ~= "number" then return false end
    local s = tostring(cbid)
    if #s == 0 or #s > 128 then return false end
    return true
end

local function rateAllow(identifier)
    if not identifier then return false end
    local now = os.time()
    local entry = _action_rate[identifier]
    if not entry or (now - entry.window_start) > RATE_WINDOW then
        _action_rate[identifier] = { count = 1, window_start = now }
        return true
    end
    if entry.count >= RATE_MAX then
        entry.count = entry.count + 1 -- keep tracking
        return false
    end
    entry.count = entry.count + 1
    return true
end

local function validateIdentityPayload(identity)
    if type(identity) ~= "table" then return false, "invalid_type" end
    -- validate names
    local fn = identity.firstname or identity.first_name or identity.firstName
    local ln = identity.lastname or identity.last_name or identity.lastName
    if fn and type(fn) ~= "string" then return false, "firstname_type" end
    if ln and type(ln) ~= "string" then return false, "lastname_type" end
    if fn and #fn > 64 then return false, "firstname_length" end
    if ln and #ln > 64 then return false, "lastname_length" end

    -- validate job
    if identity.job then
        if type(identity.job) == "table" then
            if identity.job.name and type(identity.job.name) ~= "string" then return false, "job_name_type" end
            if identity.job.grade and type(identity.job.grade) ~= "number" then return false, "job_grade_type" end
            if identity.job.grade and (identity.job.grade < 0 or identity.job.grade > 100) then return false, "job_grade_range" end
        else
            if type(identity.job) ~= "string" then return false, "job_type" end
        end
    end

    -- numeric checks for cash/bank
    if identity.cash and type(identity.cash) ~= "number" and type(identity.cash) ~= "string" then return false, "cash_type" end
    if identity.bank and type(identity.bank) ~= "number" and type(identity.bank) ~= "string" then return false, "bank_type" end

    -- limit JSON-like fields size (if tables)
    local function smallTable(t)
        if type(t) ~= "table" then return true end
        local c = 0
        for k,v in pairs(t) do
            c = c + 1
            if c > 200 then return false end
        end
        return true
    end
    if not smallTable(identity.coords) then return false, "coords_too_large" end
    if not smallTable(identity.inventory) then return false, "inventory_too_large" end
    if not smallTable(identity.skin) then return false, "skin_too_large" end
    if not smallTable(identity.metadata) then return false, "metadata_too_large" end

    return true
end

-- Handlers server pour requests clients (sécurisés)
RegisterNetEvent("shadow:player:getIdentity")
AddEventHandler("shadow:player:getIdentity", function(cbid)
    local src = source
    if not isValidCbid(cbid) then
        print(("[shadow] Invalid cbid from %s for getIdentity"):format(tostring(src)))
        return
    end
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then
        TriggerClientEvent("shadow:player:response", src, "getIdentity", cbid, false, "no_identifier")
        return
    end
    if not rateAllow(identifier) then
        print(("[shadow] Rate limit hit for %s on getIdentity"):format(identifier))
        TriggerClientEvent("shadow:player:response", src, "getIdentity", cbid, false, "rate_limited")
        return
    end

    Shadow.GetPlayerIdentity(src, function(identity)
        local ok = identity ~= nil
        TriggerClientEvent("shadow:player:response", src, "getIdentity", cbid, ok, identity)
    end)
end)

RegisterNetEvent("shadow:player:removeIdentity")
AddEventHandler("shadow:player:removeIdentity", function(cbid)
    local src = source
    if not isValidCbid(cbid) then
        print(("[shadow] Invalid cbid from %s for removeIdentity"):format(tostring(src)))
        return
    end
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then
        TriggerClientEvent("shadow:player:response", src, "removeIdentity", cbid, false, "no_identifier")
        return
    end
    if not rateAllow(identifier) then
        print(("[shadow] Rate limit hit for %s on removeIdentity"):format(identifier))
        TriggerClientEvent("shadow:player:response", src, "removeIdentity", cbid, false, "rate_limited")
        return
    end

    Shadow.RemovePlayerIdentity(src, function(success, payload)
        TriggerClientEvent("shadow:player:response", src, "removeIdentity", cbid, success, payload)
    end)
end)

RegisterNetEvent("shadow:player:setIdentity")
AddEventHandler("shadow:player:setIdentity", function(cbid, identity)
    local src = source
    if not isValidCbid(cbid) then
        print(("[shadow] Invalid cbid from %s for setIdentity"):format(tostring(src)))
        return
    end
    local identifier = GetPlayerIdentifier(src, 0)
    if not identifier then
        TriggerClientEvent("shadow:player:response", src, "setIdentity", cbid, false, "no_identifier")
        return
    end
    if not rateAllow(identifier) then
        print(("[shadow] Rate limit hit for %s on setIdentity"):format(identifier))
        TriggerClientEvent("shadow:player:response", src, "setIdentity", cbid, false, "rate_limited")
        return
    end

    local ok, err = validateIdentityPayload(identity)
    if not ok then
        print(("[shadow] Invalid identity payload from %s: %s"):format(identifier, tostring(err)))
        TriggerClientEvent("shadow:player:response", src, "setIdentity", cbid, false, err)
        return
    end

    Shadow.SetPlayerIdentity(src, identity, function(success, payload)
        TriggerClientEvent("shadow:player:response", src, "setIdentity", cbid, success, payload)
    end)
end)

Shadow.RemovePlayerIdentity = function(source, cb)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then
        if cb then cb(nil) end
        return
    end

    -- Suppression de l'identité du joueur dans la base de données
    Shadow.DB.Execute("DELETE FROM players WHERE identifier = ?", {identifier}, function(affectedRows)
        if affectedRows > 0 then
            print(("Identité du joueur %s supprimée."):format(identifier))
            if cb then cb(true, affectedRows) end
        else
            print(("Aucune identité trouvée pour le joueur %s."):format(identifier))
            if cb then cb(false, affectedRows) end
        end
    end)
end

Shadow.SetPlayerIdentity = function(source, identity, cb)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then
        if cb then cb(nil) end
        return
    end

    -- Normalisation des champs d'entrée
    local first_name = identity.firstname or identity.first_name or identity.firstName or ""
    local last_name = identity.lastname or identity.last_name or identity.lastName or ""
    local dob = identity.dob or nil
    local sex = identity.sex or nil
    local job = (identity.job and (identity.job.name or identity.job)) or "citizen"
    local job_grade = (identity.job and (identity.job.grade or identity.job_grade)) or (identity.job_grade or 0)
    local crew = (identity.crew and (identity.crew.name or identity.crew)) or "none"
    local crew_grade = (identity.crew and (identity.crew.grade or identity.crew_grade)) or (identity.crew_grade or 0)
    local cash = tonumber(identity.cash) or 0
    local bank = tonumber(identity.bank) or 0

    -- Champs JSON (encode si json.encode disponible)
    local coords = identity.coords and (json and json.encode and json.encode(identity.coords) or nil) or nil
    local inventory = identity.inventory and (json and json.encode and json.encode(identity.inventory) or nil) or nil
    local skin = identity.skin and (json and json.encode and json.encode(identity.skin) or nil) or nil
    local metadata = identity.metadata and (json and json.encode and json.encode(identity.metadata) or nil) or nil

    -- Horodatage de dernière connexion
    local last_connect = os.date("%Y-%m-%d %H:%M:%S")

    -- Requête: insert ou update selon l'identifiant (PRIMARY KEY)
    local query = [[
        INSERT INTO players (identifier, first_name, last_name, dob, sex, job, job_grade, crew, crew_grade, cash, bank, coords, inventory, skin, metadata, last_connect)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            first_name = VALUES(first_name),
            last_name = VALUES(last_name),
            dob = VALUES(dob),
            sex = VALUES(sex),
            job = VALUES(job),
            job_grade = VALUES(job_grade),
            crew = VALUES(crew),
            crew_grade = VALUES(crew_grade),
            cash = VALUES(cash),
            bank = VALUES(bank),
            coords = VALUES(coords),
            inventory = VALUES(inventory),
            skin = VALUES(skin),
            metadata = VALUES(metadata),
            last_connect = VALUES(last_connect)
    ]]

    local params = {identifier, first_name, last_name, dob, sex, job, job_grade, crew, crew_grade, cash, bank, coords, inventory, skin, metadata, last_connect}

    Shadow.DB.Execute(query, params, function(affected)
        if affected and affected > 0 then
            if cb then cb(true, affected) end
        else
            if cb then cb(false, affected) end
        end
    end)
end
