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

local test = require "integration_test"
local t_utils = require "integration_test.utils"
local capabilities = require "st.capabilities"

local clusters = require "st.matter.clusters"

local child_profile = t_utils.get_profile_definition("plug-binary.yml")
local child_profile_override = t_utils.get_profile_definition("switch-binary.yml")
local parent_ep = 10
local child1_ep = 20
local child2_ep = 30
local child3_ep = 40
local child4_ep = 50

local mock_device = test.mock_device.build_test_matter_device({
  label = "Matter Switch",
  profile = t_utils.get_profile_definition("plug-binary.yml"),
  manufacturer_info = {
    vendor_id = 0x0000,
    product_id = 0x0000,
  },
  endpoints = {
    {
      endpoint_id = 0,
      clusters = {
        {cluster_id = clusters.Basic.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x0016, device_type_revision = 1} -- RootNode
      }
    },
    {
      endpoint_id = parent_ep,
      clusters = {
        {cluster_id = clusters.OnOff.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x010A, device_type_revision = 2} -- On/Off Plug
      }
    },
    {
      endpoint_id = child1_ep,
      clusters = {
        {cluster_id = clusters.OnOff.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x010A, device_type_revision = 2} -- On/Off Plug
      }
    },
    {
      endpoint_id = child2_ep,
      clusters = {
        {cluster_id = clusters.OnOff.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x010A, device_type_revision = 2} -- On/Off Plug
      }
    },
    {
      endpoint_id = child3_ep,
      clusters = {
        {cluster_id = clusters.OnOff.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x010A, device_type_revision = 2} -- On/Off Plug
      }
    },
    {
      endpoint_id = child4_ep,
      clusters = {
        {cluster_id = clusters.OnOff.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x010A, device_type_revision = 2} -- On/Off Plug
      }
    }
  }
})

local mock_device_child_profile_override = test.mock_device.build_test_matter_device({
  label = "Matter Switch",
  profile = t_utils.get_profile_definition("switch-binary.yml"),
  manufacturer_info = {
    vendor_id = 0x1321,
    product_id = 0x000D,
  },
  endpoints = {
    {
      endpoint_id = 0,
      clusters = {
        {cluster_id = clusters.Basic.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x0016, device_type_revision = 1} -- RootNode
      }
    },
    {
      endpoint_id = parent_ep,
      clusters = {
        {cluster_id = clusters.OnOff.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x010A, device_type_revision = 2} -- On/Off Plug
      }
    },
    {
      endpoint_id = child1_ep,
      clusters = {
        {cluster_id = clusters.OnOff.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x010A, device_type_revision = 2} -- On/Off Plug
      }
    },
    {
      endpoint_id = child2_ep,
      clusters = {
        {cluster_id = clusters.OnOff.ID, cluster_type = "SERVER"},
      },
      device_types = {
        {device_type_id = 0x010A, device_type_revision = 2} -- On/Off Plug
      }
    },
  }
})

local mock_children = {}
for i, endpoint in ipairs(mock_device.endpoints) do
  if endpoint.endpoint_id ~= parent_ep and endpoint.endpoint_id ~= 0 then
    local child_data = {
      profile = child_profile,
      device_network_id = string.format("%s:%d", mock_device.id, endpoint.endpoint_id),
      parent_device_id = mock_device.id,
      parent_assigned_child_key = string.format("%d", endpoint.endpoint_id)
    }
    mock_children[endpoint.endpoint_id] = test.mock_device.build_test_child_device(child_data)
  end
end

local function test_init()
  local cluster_subscribe_list = {
    clusters.OnOff.attributes.OnOff,
  }
  local subscribe_request = cluster_subscribe_list[1]:subscribe(mock_device)
  test.socket.matter:__expect_send({mock_device.id, subscribe_request})

  mock_device:set_field("__ELECTRICAL_TOPOLOGY", {topology = false, tags_on_ep = {}}, {persist = false}) -- since we're assuming this would have happened during device_added in this case.
  test.socket.device_lifecycle:__queue_receive({ mock_device.id, "doConfigure" })
  mock_device:expect_metadata_update({ profile = "plug-binary" })
  mock_device:expect_metadata_update({ provisioning_state = "PROVISIONED" })

  test.mock_device.add_test_device(mock_device)
  for _, child in pairs(mock_children) do
    test.mock_device.add_test_device(child)
  end

  mock_device:expect_device_create({
    type = "EDGE_CHILD",
    label = "Matter Switch 2",
    profile = "plug-binary",
    parent_device_id = mock_device.id,
    parent_assigned_child_key = string.format("%d", child1_ep)
  })

  mock_device:expect_device_create({
    type = "EDGE_CHILD",
    label = "Matter Switch 3",
    profile = "plug-binary",
    parent_device_id = mock_device.id,
    parent_assigned_child_key = string.format("%d", child2_ep)
  })

  mock_device:expect_device_create({
    type = "EDGE_CHILD",
    label = "Matter Switch 4",
    profile = "plug-binary",
    parent_device_id = mock_device.id,
    parent_assigned_child_key = string.format("%d", child3_ep)
  })

  mock_device:expect_device_create({
    type = "EDGE_CHILD",
    label = "Matter Switch 5",
    profile = "plug-binary",
    parent_device_id = mock_device.id,
    parent_assigned_child_key = string.format("%d", child4_ep)
  })
end

local mock_children_child_profile_override = {}
for i, endpoint in ipairs(mock_device_child_profile_override.endpoints) do
  if endpoint.endpoint_id ~= parent_ep and endpoint.endpoint_id ~= 0 then
    local child_data = {
      profile = child_profile_override,
      device_network_id = string.format("%s:%d", mock_device_child_profile_override.id, endpoint.endpoint_id),
      parent_device_id = mock_device_child_profile_override.id,
      parent_assigned_child_key = string.format("%d", endpoint.endpoint_id)
    }
    mock_children_child_profile_override[endpoint.endpoint_id] = test.mock_device.build_test_child_device(child_data)
  end
end

local function test_init_child_profile_override()
  local cluster_subscribe_list = {
    clusters.OnOff.attributes.OnOff,
  }
  local subscribe_request = cluster_subscribe_list[1]:subscribe(mock_device_child_profile_override)
  test.socket.matter:__expect_send({mock_device_child_profile_override.id, subscribe_request})

  mock_device_child_profile_override:set_field("__ELECTRICAL_TOPOLOGY", {topology = false, tags_on_ep = {}}, {persist = false}) -- since we're assuming this would have happened during device_added in this case.
  test.socket.device_lifecycle:__queue_receive({ mock_device_child_profile_override.id, "doConfigure" })
  mock_device_child_profile_override:expect_metadata_update({ profile = "plug-binary" })
  mock_device_child_profile_override:expect_metadata_update({ provisioning_state = "PROVISIONED" })

  test.mock_device.add_test_device(mock_device_child_profile_override)
  for _, child in pairs(mock_children_child_profile_override) do
    test.mock_device.add_test_device(child)
  end

  mock_device:expect_device_create({
    type = "EDGE_CHILD",
    label = "Matter Switch 2",
    profile = "switch-binary",
    parent_device_id = mock_device_child_profile_override.id,
    parent_assigned_child_key = string.format("%d", child1_ep)
  })

  mock_device:expect_device_create({
    type = "EDGE_CHILD",
    label = "Matter Switch 3",
    profile = "switch-binary",
    parent_device_id = mock_device_child_profile_override.id,
    parent_assigned_child_key = string.format("%d", child2_ep)
  })
end

test.set_test_init_function(test_init)

test.register_message_test(
  "Parent device: switch capability should send the appropriate commands",
  {
    {
      channel = "capability",
      direction = "receive",
      message = {
        mock_device.id,
        { capability = "switch", component = "main", command = "on", args = { } }
      }
    },
    {
      channel = "devices",
      direction = "send",
      message = {
        "register_native_capability_cmd_handler",
        { device_uuid = mock_device.id, capability_id = "switch", capability_cmd_id = "on" }
      }
    },
    {
      channel = "matter",
      direction = "send",
      message = {
        mock_device.id,
        clusters.OnOff.server.commands.On(mock_device, parent_ep)
      },
    },
    {
      channel = "matter",
      direction = "receive",
      message = {
        mock_device.id,
        clusters.OnOff.attributes.OnOff:build_test_report_data(mock_device, parent_ep, true)
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_device:generate_test_message("main", capabilities.switch.switch.on())
    },
    {
      channel = "devices",
      direction = "send",
      message = {
        "register_native_capability_attr_handler",
        { device_uuid = mock_device.id, capability_id = "switch", capability_attr_id = "switch" }
      }
    },
  }
)

test.register_message_test(
  "First child device: switch capability switch should send the appropriate commands",
  {
    {
      channel = "capability",
      direction = "receive",
      message = {
        mock_children[child1_ep].id,
        { capability = "switch", component = "main", command = "on", args = { } }
      }
    },
    {
      channel = "devices",
      direction = "send",
      message = {
        "register_native_capability_cmd_handler",
        { device_uuid = mock_children[child1_ep].id, capability_id = "switch", capability_cmd_id = "on" }
      }
    },
    {
      channel = "matter",
      direction = "send",
      message = {
        mock_device.id,
        clusters.OnOff.server.commands.On(mock_device, child1_ep)
      }
    },
    {
      channel = "matter",
      direction = "receive",
      message = {
        mock_device.id,
        clusters.OnOff.attributes.OnOff:build_test_report_data(mock_device, child1_ep, true)
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_children[child1_ep]:generate_test_message("main", capabilities.switch.switch.on())
    },
    {
      channel = "devices",
      direction = "send",
      message = {
        "register_native_capability_attr_handler",
        { device_uuid = mock_device.id, capability_id = "switch", capability_attr_id = "switch" }
      }
    },
  }
)

test.register_message_test(
  "Second child device: switch capability should send the appropriate commands",
  {
    {
      channel = "capability",
      direction = "receive",
      message = {
        mock_children[child2_ep].id,
        { capability = "switch", component = "main", command = "on", args = { } }
      }
    },
    {
      channel = "devices",
      direction = "send",
      message = {
        "register_native_capability_cmd_handler",
        { device_uuid = mock_children[child2_ep].id, capability_id = "switch", capability_cmd_id = "on" }
      }
    },
    {
      channel = "matter",
      direction = "send",
      message = {
        mock_device.id,
        clusters.OnOff.server.commands.On(mock_device, child2_ep)
      }
    },
    {
      channel = "matter",
      direction = "receive",
      message = {
        mock_device.id,
        clusters.OnOff.attributes.OnOff:build_test_report_data(mock_device, child2_ep, true)
      }
    },
    {
      channel = "capability",
      direction = "send",
      message = mock_children[child2_ep]:generate_test_message("main", capabilities.switch.switch.on())
    },
    {
      channel = "devices",
      direction = "send",
      message = {
        "register_native_capability_attr_handler",
        { device_uuid = mock_device.id, capability_id = "switch", capability_attr_id = "switch" }
      }
    },
  }
)

test.register_coroutine_test(
  "Added should call refresh for child devices", function()
    test.socket.matter:__set_channel_ordering("relaxed")
    test.socket.device_lifecycle:__queue_receive({ mock_children[child1_ep].id, "added" })
    local req = clusters.OnOff.attributes.OnOff:read(mock_children[child1_ep])
    test.socket.matter:__expect_send({mock_device.id, req})
  end
)

test.register_coroutine_test(
  "Child device profiles should be overriden for specific devices", function()
    end,
    { test_init = test_init_child_profile_override }
)

test.run_registered_tests()
