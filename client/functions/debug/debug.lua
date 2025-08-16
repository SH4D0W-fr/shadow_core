function Debug(lvl, msg)
    if not msg then return end

    if type(lvl) ~= 'number' then return end

    if type(msg) ~= 'string' then
        msg = tostring(msg)
    end

    if lvl < 0 or lvl > 3 then
        print('Invalid debug level: ' .. tostring(lvl))
        return
    end

    -- Read configuration safely. Defaults: Debug disabled, level 0 (ERROR).
    local debugEnabled = false
    local debugLevel = 0
    if type(Config) == 'table' and type(Config.Main) == 'table' then
        if type(Config.Main.Debug) == 'boolean' then
            debugEnabled = Config.Main.Debug
        end
        if type(Config.Main.DebugLevel) == 'number' then
            debugLevel = math.floor(Config.Main.DebugLevel)
            if debugLevel < 0 then debugLevel = 0 end
            if debugLevel > 3 then debugLevel = 3 end
        end
    end

    -- If debug is disabled, only show errors (level 0).
    if not debugEnabled and lvl ~= 0 then
        return
    end

    -- If debug is enabled, only show messages up to the configured level.
    if debugEnabled and lvl > debugLevel then
        return
    end

    local levels = {
        [0] = 'ERROR',
        [1] = 'WARNING',
        [2] = 'INFO',
        [3] = 'DEBUG'
    }
    local level = levels[lvl] or 'UNKNOWN'
    local output = string.format('[%s] %s', level, msg)
    print(output)
end

exports("Debug", Debug);