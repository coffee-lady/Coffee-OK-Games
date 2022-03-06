--- @type OKGamesSDK
local OKGames = require('OKGames.okgames')
local App = require('main.app')

local Debug = App.libs.debug
local AutosaveTimeoutTimer = App.libs.AutosaveTimeoutTimer

local FilesConfig = App.config.app
local FILE = FilesConfig.file
local KEY_TIMER = FilesConfig.keys.rewarded_timer

local DEBUG = App.config.debug_mode.RewardedAdsService
local debug_logger = Debug('[OK] RewardedAdsAdapter', DEBUG)

local function exec(func, ...)
    if func then
        func(...)
    end
end

local OKRewardedAds = {}

function OKRewardedAds.init_timer(delay, data_storage_use_cases)
    OKRewardedAds.timer = AutosaveTimeoutTimer(delay)
    OKRewardedAds.timer:enable_saving(FILE, KEY_TIMER, data_storage_use_cases)
    OKRewardedAds.timer:restore_unfinished()
end

function OKRewardedAds.show(callbacks)
    callbacks = callbacks or {}
    debug_logger:log('RewardedAdsAdapter.show')

    local loaded_result = OKGames:load_rewarded_ad_async()

    if not loaded_result.status then
        exec(callbacks.error)
        debug_logger:log('error on load ad')
        return false
    end

    exec(callbacks.open)

    local show_result = OKGames:show_rewarded_ad_async()

    if not show_result.status then
        exec(callbacks.error)
        debug_logger:log('error on show ad')
        return false
    end

    exec(callbacks.rewarded)
    exec(callbacks.close)
    debug_logger:log('success on show ad')
    return true
end

function OKRewardedAds.show_on_reward(callbacks)
    if not OKRewardedAds.timer:is_expired() then
        debug_logger:log('timer is not expired. seconds left:', OKRewardedAds.timer:get_seconds_left())
        return false
    end

    return OKRewardedAds.show(callbacks)
end

return OKRewardedAds
