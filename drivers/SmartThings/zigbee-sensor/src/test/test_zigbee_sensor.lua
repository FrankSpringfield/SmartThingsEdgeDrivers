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

local test = require "integration_test"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local clusters = require "st.zigbee.zcl.clusters"
local IASZone = clusters.IASZone
local capabilities = require "st.capabilities"
local IasEnrollResponseCode = require "st.zigbee.generated.zcl_clusters.IASZone.types.EnrollResponseCode"
local t_utils = require "integration_test.utils"

local ZoneStatusAttribute = IASZone.attributes.ZoneStatus

local ZIGBEE_GENERIC_SENSOR_PROFILE = "generic-sensor"
local ZIGBEE_GENERIC_CONTACT_SENSOR_PROFILE = "generic-contact-sensor"
local ZIGBEE_GENERIC_EMERGENCY_BUTTON_PROFILE = "generic-emergency-button"
local ZIGBEE_GENERIC_MOTION_SENSOR_PROFILE = "generic-motion-sensor"
local ZIGBEE_GENERIC_WATERLEAK_SENSOR_PROFILE = "generic-waterleak-sensor"


-- How can I get a mock device with specific zonetype(attribute)?
local mock_device_generic_sensor = test.mock_device.build_test_zigbee_device(
  {
    profile = t_utils.get_profile_definition(ZIGBEE_GENERIC_SENSOR_PROFILE .. ".yml"),
    zigbee_endpoints = {
      [1] = {
        id = 1,
        manufacturer = " ",
        model = " ",
        server_clusters = { 0x0500 }
      }
    }
  }
)


local mock_device_contact_sensor = test.mock_device.build_test_zigbee_device(
  {
    profile = t_utils.get_profile_definition(ZIGBEE_GENERIC_CONTACT_SENSOR_PROFILE .. ".yml"),
    zigbee_endpoints = {
      [1] = {
        id = 1,
        manufacturer = " ",
        model = " ",
        server_clusters = { 0x0500 }
      }
    }
  }
)

local mock_device_emergency_button = test.mock_device.build_test_zigbee_device(
  {
    profile = t_utils.get_profile_definition(ZIGBEE_GENERIC_EMERGENCY_BUTTON_PROFILE .. ".yml"),
    zigbee_endpoints = {
      [1] = {
        id = 1,
        manufacturer = " ",
        model = " ",
        server_clusters = { 0x0500 }
      }
    }
  }
)

local mock_device_motions_sensor = test.mock_device.build_test_zigbee_device(
  {
    profile = t_utils.get_profile_definition(ZIGBEE_GENERIC_MOTION_SENSOR_PROFILE .. ".yml"),
    zigbee_endpoints = {
      [1] = {
        id = 1,
        manufacturer = " ",
        model = " ",
        server_clusters = { 0x0500 }
      }
    }
  }
)

local mock_device_waterleak_sensor = test.mock_device.build_test_zigbee_device(
  {
    profile = t_utils.get_profile_definition(ZIGBEE_GENERIC_WATERLEAK_SENSOR_PROFILE .. ".yml"),
    zigbee_endpoints = {
      [1] = {
        id = 1,
        manufacturer = " ",
        model = " ",
        server_clusters = { 0x0500 }
      }
    }
  }
)

zigbee_test_utils.prepare_zigbee_env_info()
local function test_init()
  test.mock_device.add_test_device(mock_device_generic_sensor)
  test.mock_device.add_test_device(mock_device_contact_sensor)
  test.mock_device.add_test_device(mock_device_emergency_button)
  test.mock_device.add_test_device(mock_device_motions_sensor)
  test.mock_device.add_test_device(mock_device_waterleak_sensor)
  zigbee_test_utils.init_noop_health_check_timer()
end

test.set_test_init_function(test_init)

-- TODO: Add tests for functions and lifecycle 

test.run_registered_tests()