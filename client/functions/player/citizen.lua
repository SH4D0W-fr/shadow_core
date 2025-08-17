-- Gestion joueur côté client
Shadow.GetCitizenData = function()
    local ped = PlayerPedId()
    return {
        coords = GetEntityCoords(ped),
        health = GetEntityHealth(ped),
        armor = GetPedArmour(ped)
    }
end
