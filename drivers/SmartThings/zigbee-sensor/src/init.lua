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

local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local clusters = require "st.zigbee.zcl.clusters"
local IASZone = clusters.IASZone
local capabilities = require "st.capabilities"
local ZONETYPE = "ZoneType"
local log = require "log"
local buf_lib = require "st.buf"
local zb_messages = require "st.zigbee.messages"
local constants = require "st.zigbee.constants"

local ZIGBEE_GENERIC_CONTACT_SENSOR_PROFILE = "ias-generic-contact-sensor"
local ZIGBEE_GENERIC_EMERGENCY_BUTTON_PROFILE = "ias-generic-emergency-button"
local ZIGBEE_GENERIC_MOTION_SENSOR_PROFILE = "ias-generic-motion-sensor"
local ZIGBEE_GENERIC_WATERLEAK_SENSOR_PROFILE = "ias-generic-waterleak-sensor"

local ias_device_init = function(driver, device)
  device:send(IASZone.attributes.ZoneType:read(device))
  log.info("Zigbee Message Sent")
end

local function update_profile(device, zone_type)
  if zone_type == 21 then
    device:try_update_metadata({profile = ZIGBEE_GENERIC_CONTACT_SENSOR_PROFILE})
  elseif zone_type == 271 or zone_type == 277 or zone_type == 541 then
    device:try_update_metadata({profile = ZIGBEE_GENERIC_EMERGENCY_BUTTON_PROFILE})
  elseif zone_type == 13 then
    device:try_update_metadata({profile = ZIGBEE_GENERIC_MOTION_SENSOR_PROFILE})
  elseif zone_type == 42 then
    device:try_update_metadata({profile = ZIGBEE_GENERIC_WATERLEAK_SENSOR_PROFILE})
  end
end

local function all_zigbee_message_handler(self, message_channel)
  local device_uuid, data = message_channel:receive()
  local device = self:get_device_info(device_uuid)
  local buf = buf_lib.Reader(data)
  local zb_rx = zb_messages.ZigbeeMessageRx.deserialize(buf, {additional_zcl_profiles = self.additional_zcl_profiles})
  if zb_rx.address_header.cluster.value == 1280 then 
    for _, v in ipairs(zb_rx.body.zcl_body.attr_records) do
      if v.data.value ~= nil then
        device:set_field(ZONETYPE, v.data.value)
        update_profile(device, v.data.value)
        break
      end
    end
  end

end

local ias_zone_type_attr_handler = function (driver, device, attr_val)
  log.info("----upload zone type")
  device:set_field(ZONETYPE, attr_val.value)
end

local zigbee_generic_sensor_template = {
  supported_capabilities = {
    capabilities.firmwareUpdate,
    capabilities.refresh
  },
  sub_drivers = {
    require("ias-generic-contact-sensor"),
    require("ias-generic-emergency-button"),
    require("ias-generic-motion-sensor"),
    require("ias-generic-waterleak-sensor")
  },
  zigbee_handlers = {
    attr = {
      [IASZone.ID] = {
        [IASZone.attributes.ZoneType.ID] = ias_zone_type_attr_handler
      }
    }
  },
  lifecycle_handlers = {
    init = ias_device_init
  }
}

defaults.register_for_default_handlers(zigbee_generic_sensor_template, zigbee_generic_sensor_template.supported_capabilities)
local zigbee_sensor = ZigbeeDriver("zigbee-sensor", zigbee_generic_sensor_template)
zigbee_sensor:run()
