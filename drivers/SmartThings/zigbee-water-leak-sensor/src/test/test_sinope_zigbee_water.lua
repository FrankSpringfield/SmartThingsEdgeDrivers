-- Copyright 2023 SmartThings
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

-- Mock out globals
local test = require "integration_test"
local clusters = require "st.zigbee.zcl.clusters"
local IASZone = clusters.IASZone
local TemperatureMeasurement = clusters.TemperatureMeasurement
local PowerConfiguration = clusters.PowerConfiguration
local capabilities = require "st.capabilities"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local IasEnrollResponseCode = require "st.zigbee.generated.zcl_clusters.IASZone.types.EnrollResponseCode"
local t_utils = require "integration_test.utils"

local ZoneStatusAttribute = IASZone.attributes.ZoneStatus

local mock_device = test.mock_device.build_test_zigbee_device(
    {
      profile = t_utils.get_profile_definition("water-temp-battery.yml"),
      zigbee_endpoints = {
        [1] = {
          id = 1,
          manufacturer = "Sinope Technologies",
          model = "WL4210",
          server_clusters = {0x0001, 0x0402, 0x0500}
        }
      }
    }
)
zigbee_test_utils.prepare_zigbee_env_info()
local function test_init()
  test.mock_device.add_test_device(mock_device)end
test.set_test_init_function(test_init)

test.register_message_test(
    "Reported water should be handled: wet",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, ZoneStatusAttribute:build_test_attr_report(mock_device, 0x0001) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.waterSensor.water.wet())
      }
    }
)

test.register_message_test(
    "Reported water should be handled: dry",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, ZoneStatusAttribute:build_test_attr_report(mock_device, 0x0000) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.waterSensor.water.dry())
      }
    }
)

test.register_message_test(
    "Reported water should be handled: dry",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, ZoneStatusAttribute:build_test_attr_report(mock_device, 0x0002) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.waterSensor.water.dry())
      }
    }
)

test.register_message_test(
    "ZoneStatusChangeNotification should be handled: wet",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, IASZone.client.commands.ZoneStatusChangeNotification.build_test_rx(mock_device, 0x0001, 0x00) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.waterSensor.water.wet())
      }
    }
)

test.register_message_test(
    "ZoneStatusChangeNotification should be handled: dry",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, IASZone.client.commands.ZoneStatusChangeNotification.build_test_rx(mock_device, 0x0000, 0x00) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.waterSensor.water.dry())
      }
    }
)

test.register_message_test(
    "Temperature report should be handled",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, TemperatureMeasurement.attributes.MeasuredValue:build_test_attr_report(mock_device, 2500) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.temperatureMeasurement.temperature({ value = 25.0, unit = "C" }))
      }
    }
)

test.register_message_test(
    "Battery percentage report should be handled",
    {
      {
        channel = "zigbee",
        direction = "receive",
        message = { mock_device.id, PowerConfiguration.attributes.BatteryPercentageRemaining:build_test_attr_report(mock_device, 55) }
      },
      {
        channel = "capability",
        direction = "send",
        message = mock_device:generate_test_message("main", capabilities.battery.battery(28))
      }
    }
)

-- test.register_coroutine_test(
--     "Health check should check all relevant attributes",
--     function()
--       test.socket.device_lifecycle:__queue_receive({mock_device.id, "added"})
--       test.socket.zigbee:__expect_send({
--         mock_device.id,
--         TemperatureMeasurement.attributes.MaxMeasuredValue:read(mock_device)
--       })
--       test.socket.zigbee:__expect_send({
--         mock_device.id,
--         TemperatureMeasurement.attributes.MinMeasuredValue:read(mock_device)
--       })
--       test.wait_for_events()

--       test.mock_time.advance_time(50000) -- battery is 21600 for max reporting interval
--       test.socket.zigbee:__set_channel_ordering("relaxed")
--       test.socket.zigbee:__expect_send(
--           {
--             mock_device.id,
--             TemperatureMeasurement.attributes.MeasuredValue:read(mock_device)
--           }
--       )
--       test.socket.zigbee:__expect_send(
--           {
--             mock_device.id,
--             PowerConfiguration.attributes.BatteryPercentageRemaining:read(mock_device)
--           }
--       )
--       test.socket.zigbee:__expect_send(
--           {
--             mock_device.id,
--             IASZone.attributes.ZoneStatus:read(mock_device)
--           }
--       )
--     end,
--     {
--       test_init = function()
--         test.mock_device.add_test_device(mock_device)
--         test.timer.__create_and_queue_test_time_advance_timer(30, "interval", "health_check")
--       end
--     }
-- )

test.register_coroutine_test(
    "Configure should configure all necessary attributes",
    function ()
      test.socket.zigbee:__set_channel_ordering("relaxed")
      test.socket.device_lifecycle:__queue_receive({ mock_device.id, "added"})
      test.socket.zigbee:__expect_send({
        mock_device.id,
        TemperatureMeasurement.attributes.MaxMeasuredValue:read(mock_device)
      })
      test.socket.zigbee:__expect_send({
        mock_device.id,
        TemperatureMeasurement.attributes.MinMeasuredValue:read(mock_device)
      })
      test.socket.device_lifecycle:__queue_receive({ mock_device.id, "doConfigure"})
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         PowerConfiguration.attributes.BatteryPercentageRemaining:read(mock_device)
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         TemperatureMeasurement.attributes.MeasuredValue:read(mock_device)
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         IASZone.attributes.ZoneStatus:read(mock_device)
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         TemperatureMeasurement.attributes.MeasuredValue:configure_reporting(
                                             mock_device,
                                             30,
                                             600,
                                             100
                                         )
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         zigbee_test_utils.build_bind_request(
                                             mock_device,
                                             zigbee_test_utils.mock_hub_eui,
                                             TemperatureMeasurement.ID
                                         )
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         PowerConfiguration.attributes.BatteryPercentageRemaining:configure_reporting(
                                             mock_device,
                                             30,
                                             21600,
                                             1
                                         )
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         zigbee_test_utils.build_bind_request(
                                             mock_device,
                                             zigbee_test_utils.mock_hub_eui,
                                             PowerConfiguration.ID
                                         )
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         IASZone.attributes.IASCIEAddress:write(
                                             mock_device,
                                             zigbee_test_utils.mock_hub_eui
                                         )
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         IASZone.server.commands.ZoneEnrollResponse(
                                             mock_device,
                                             IasEnrollResponseCode.SUCCESS,
                                             0x00
                                         )
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         IASZone.attributes.ZoneStatus:configure_reporting(
                                             mock_device,
                                             30,
                                             300,
                                             0
                                         )
                                       })
      test.socket.zigbee:__expect_send({
                                         mock_device.id,
                                         zigbee_test_utils.build_bind_request(
                                             mock_device,
                                             zigbee_test_utils.mock_hub_eui,
                                             IASZone.ID
                                         )
                                       })

      mock_device:expect_metadata_update({ provisioning_state = "PROVISIONED" })
    end
)

test.register_message_test(
    "Refresh should read all necessary attributes",
    {
      {
        channel = "device_lifecycle",
        direction = "receive",
        message = {mock_device.id, "added"}
      },
      {
        channel = "zigbee",
        direction = "send",
        message = {
          mock_device.id,
          TemperatureMeasurement.attributes.MaxMeasuredValue:read(mock_device)
        }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = {
          mock_device.id,
          TemperatureMeasurement.attributes.MinMeasuredValue:read(mock_device)
        }
      },
      {
        channel = "capability",
        direction = "receive",
        message = {
          mock_device.id,
          { capability = "refresh", component = "main", command = "refresh", args = {} }
        }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = {
          mock_device.id,
          PowerConfiguration.attributes.BatteryPercentageRemaining:read(mock_device)
        }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = {
          mock_device.id,
          TemperatureMeasurement.attributes.MeasuredValue:read(mock_device)
        }
      },
      {
        channel = "zigbee",
        direction = "send",
        message = {
          mock_device.id,
          IASZone.attributes.ZoneStatus:read(mock_device)
        }
      },
    },
    {
      inner_block_ordering = "relaxed"
    }
)

test.run_registered_tests()
