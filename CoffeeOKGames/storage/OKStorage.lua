local Nakama = require('CoffeeOKGames.nakama.nakama')

local FILE_TMP = 'temp'
local KEY_DATA_VERSION = 'data_version'
local DEFAULT_DATA_VERSION = '*'

local SAVE_DELAY = 3

local OKStorage = class('OKStorage')

OKStorage.__cparams = {'local_storage'}

function OKStorage:initialize(local_storage)
    self.requests_to_write_queue = {}

    self.write_data_timer =
        timer.delay(
        SAVE_DELAY,
        true,
        function()
            Async.bootstrap(
                function()
                    self:_post_write_requests_async()
                end
            )
        end
    )

    self.event_save_error = Event()
end

function OKStorage:set(filename, key, value)
    self:_add_to_write_queue(filename, key, value)
end

function OKStorage:get_key(filename, key)
    return filename .. key
end

function OKStorage:get_all_async(filename, keys)
    local request_data = {}

    for _, key in pairs(keys) do
        request_data[#request_data + 1] = {
            collection = filename,
            key = key
        }
    end

    local response = Nakama:load_data_async(request_data)

    if not response or response.rc ~= 0 then
        return {}
    end

    local data = {}

    for _, content_item in pairs(response.content) do
        local item_key = self:get_key(filename, content_item.key)
        data[item_key] = content_item.value.value

        local key_data_version = self:get_key(KEY_DATA_VERSION, item_key)
        self.local_storage:set(FILE_TMP, key_data_version, content_item.version)
    end

    return data
end

function OKStorage:_add_to_write_queue(filename, key, value)
    for i = 1, #self.requests_to_write_queue do
        local item = self.requests_to_write_queue[i]

        if item.filename == filename and item.key == key then
            item.value = value
            return
        end
    end

    self.requests_to_write_queue[#self.requests_to_write_queue + 1] = {
        filename = filename,
        key = key,
        value = value
    }
end

function OKStorage:_post_write_requests_async()
    if #self.requests_to_write_queue == 0 then
        return
    end

    local request_data = {}

    for i = #self.requests_to_write_queue, 1, -1 do
        local item = self.requests_to_write_queue[i]
        local item_key = self:get_key(item.filename, item.key)
        local key_data_version = self:get_key(KEY_DATA_VERSION, item_key)
        local prev_data_version = self.local_storage:get(FILE_TMP, key_data_version) or DEFAULT_DATA_VERSION

        request_data[#request_data + 1] = {
            collection = item.filename,
            key = item.key,
            value = {
                value = item.value
            },
            version = prev_data_version
        }

        table.remove(self.requests_to_write_queue)
    end

    local response = Nakama:write_data_async(request_data)

    if not response then
        return
    end

    if response.rc ~= 0 then
        self.event_save_error:emit()
        return
    end

    for i = 1, #response.content do
        local response_item_data = response.content[i]
        local item_key = self:get_key(response_item_data.collection, response_item_data.key)
        local key_data_version = self:get_key(KEY_DATA_VERSION, item_key)
        self.local_storage:set(FILE_TMP, key_data_version, response_item_data.version)
    end
end

return OKStorage
