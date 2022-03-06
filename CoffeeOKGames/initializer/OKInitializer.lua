local App = require('main.app')
--- @type OKGamesSDK
local OKGames = require('OKGames.okgames')
local Nakama = require('nakama.nakama')
local engine_defold = require('nakama.engine.defold')
local Mock = require('main.scripts.common.platform.ok.adapters.mock.mock')
local NakamaAdapter = require('main.scripts.common.platform.common.adapters.nakama.nakama_adapter')

local Async = App.libs.async

local OKInitializer = class('OKInitializer')

OKInitializer.__cparams = {'scenes_service'}

function OKInitializer:initialize(scenes_service, server_config)
    --- @type ScreenService
    self.scenes_service = scenes_service

    OKGames:setup_mock(Mock)
    OKGames:init_async()

    NakamaAdapter:init(Nakama, engine_defold, server_config)

    self:on_resize()

    self.screen_service.event_resize:add(self.on_resize, self)
end

function OKInitializer:on_resize()
    Async.bootstrap(function()
        local result = OKGames:get_page_info_async()

        if not result.status then
            return
        end

        local page_info = result.data

        OKGames:set_window_size({width = page_info.clientWidth, height = page_info.clientHeight - page_info.offsetTop})
    end)
end

return OKInitializer
