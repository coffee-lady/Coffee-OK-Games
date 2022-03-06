--- @type OKGamesSDK
local OKGames = require('OKGames.okgames')
local App = require('main.app')

local Debug = App.libs.debug
local AutosaveTimeoutTimer = App.libs.AutosaveTimeoutTimer

local FilesConfig = App.config.app
local FILE = FilesConfig.file
local KEY_TIMER = FilesConfig.keys.interstitial_timer

local DEBUG = App.config.debug_mode.InterstitialAdsService
local debug_logger = Debug('[OK] InterstitialAdsAdapter', DEBUG)

local function exec(func, ...)
    if func then func(...) end
end

local OKInterstitialAds = {}

function OKInterstitialAds.init_timer(delay, data_storage_use_cases)
    OKInterstitialAds.timer = AutosaveTimeoutTimer(delay)
    OKInterstitialAds.timer:enable_saving(FILE, KEY_TIMER, data_storage_use_cases)
    OKInterstitialAds.timer:restore_unfinished()
end

function OKInterstitialAds.show(callbacks)
    if not OKInterstitialAds.timer:is_expired() then
        debug_logger:log('timer is not expired. seconds_left:', OKInterstitialAds.timer.seconds_left)
        return
    end

    callbacks = callbacks or {}

    exec(callbacks.open)

    local result = OKGames:show_interstitial_ad_async()

    if result.status then
        exec(callbacks.close, true)
    else
        exec(callbacks.error)
    end
end

function OKInterstitialAds.show_with_probability(probability, callbacks)
    callbacks = callbacks or {}

    if probability == 0 then return end

    local show_ad = math.random() <= probability

    if not show_ad then
        debug_logger:log('ad will not be shown because of probability')
        exec(callbacks.close, false)
        return
    end

    OKInterstitialAds.show(callbacks)
end

function OKInterstitialAds.resume_timer()
    OKInterstitialAds.timer:resume()
end

return OKInterstitialAds
