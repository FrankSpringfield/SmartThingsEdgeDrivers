-- Copyright 2025 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
local log = require "log"
local ZONETYPE = "ZoneType"

local is_waterleak_sensor = function(opts, driver, device)
    local type = device:get_field(ZONETYPE)
    if type == 42 then
        log.info("water leak")
        return true
    end
    return false
end

local zigbee_waterleak_sensor_handler = {
  NAME = "IAS Generic Water Leak Sensor",
  can_handle = is_waterleak_sensor
}

return zigbee_waterleak_sensor_handler