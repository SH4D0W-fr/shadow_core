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


Shadow.DB.Initiate = function()
    if not MySQL then
        error("MySQL library is not loaded. Please ensure it is properly installed and configured.")
    else
        Shadow.DB.Execute([[
            CREATE TABLE IF NOT EXISTS `players` (
                `identifier` VARCHAR(255) NOT NULL UNIQUE PRIMARY KEY,
                `id` VARCHAR(64) DEFAULT NULL AUTO_INCREMENT,
                `first_name` VARCHAR(100) DEFAULT NULL,
                `last_name` VARCHAR(100) DEFAULT NULL,
                `dob` DATE DEFAULT NULL,
                `sex` VARCHAR(10) DEFAULT NULL,
                `job` VARCHAR(100) DEFAULT 'citizen',
                `job_grade` INT DEFAULT 0,
                `crew` VARCHAR(100) DEFAULT 'none',
                `crew_grade` INT DEFAULT 0,
                `cash` BIGINT DEFAULT 0,
                `bank` BIGINT DEFAULT 0,
                `coords` JSON DEFAULT NULL,
                `inventory` JSON DEFAULT NULL,
                `skin` JSON DEFAULT NULL,
                `metadata` JSON DEFAULT NULL,
                `last_connect` TIMESTAMP NULL DEFAULT NULL,
                `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], {}, function(affected)
            if affected > 0 then
                print("Shadow DB initialized successfully.")
            else
                print("Shadow DB already exists or no changes made.")
            end
        end)
    end
end
