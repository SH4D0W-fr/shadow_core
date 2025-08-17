-- Gestion joueur côté serveur
Shadow.GetCitizenFromId = function(source)
    local identifier = GetPlayerIdentifier(source, 0)
    local citizen = {
        source = source,
        identifier = identifier,
        cash = 0,
        bank = 0,
        job = {name = "unemployed", grade = 0}
    }
    return citizen
end

Shadow.AddMoney = function(source, account, amount)
    -- Exemple : ajout argent
    print(("Ajout de %s à %s (%s)"):format(amount, source, account))
end
