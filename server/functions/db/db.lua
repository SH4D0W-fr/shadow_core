-- Gestion DB générique
Shadow.DB = {}

Shadow.DB.FetchAll = function(query, params, cb)
    MySQL.query(query, params, function(result)
        if cb then cb(result) end
    end)
end

Shadow.DB.Execute = function(query, params, cb)
    MySQL.update(query, params, function(affected)
        if cb then cb(affected) end
    end)
end
