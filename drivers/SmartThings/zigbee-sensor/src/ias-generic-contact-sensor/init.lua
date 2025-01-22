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

local ZONETYPE = "ZoneType"
local log = require "log"
local capabilities = require "st.capabilities"
local clusters = require "st.zigbee.zcl.clusters"
local IASZone = clusters.IASZone
local constants = require "st.zigbee.constants"
local ZIGBEE_GENERIC_CONTACT_SENSOR_PROFILE = "ias-generic-contact-sensor"

local is_contact_sensor = function(opts, driver, device, ...)
  local type = device:get_field(ZONETYPE)
  if type == 21 then
    log.info("contact sensor")
    device:try_update_metadata({profile = ZIGBEE_GENERIC_CONTACT_SENSOR_PROFILE})
    return true
  end
  return false
end

local CONFIGURATIONS = {
  {
    cluster = IASZone.ID,
    attribute = IASZone.attributes.ZoneStatus.ID,
    minimum_interval = 30,
    maximum_interval = 300,
    data_type = IASZone.attributes.ZoneStatus.base_type,
    reportable_change = 1
  }
}

local function contact_device_added(driver, device)
  log.info("----device_added")
  for _, attribute in ipairs(CONFIGURATIONS) do
    device:add_configured_attribute(attribute)
    device:add_monitored_attribute(attribute)
  end
end

local zigbee_generic_contact_sensor_handler = {
  NAME = "IAS Generic Contact Sensor",
  supported_capabilities = {
    capabilities.contactSensor,
  },
  lifecycle_handlers = {
    added = contact_device_added
  },
  can_handle = is_contact_sensor
}

return zigbee_generic_contact_sensor_handler
