-- Copyright 2022 SmartThings
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

local clusters = require "st.zigbee.zcl.clusters"
local cluster_base = require "st.zigbee.cluster_base"
local data_types = require "st.zigbee.data_types"
local OnOff = clusters.OnOff
local log = require "log"


local POWER_ON_VALUES = {
  off = OnOff.attributes.StartUpOnOff.SET_ON_OFF_TO0,
  on = OnOff.attributes.StartUpOnOff.SET_ON_OFF_TO1,
  toggle = OnOff.attributes.StartUpOnOff.TOGGLE_PREVIOUS_ON_OFF,
  previous = OnOff.attributes.StartUpOnOff.SET_PREVIOUS_ON_OFF,
}

local devices = {
  AQARA_LIGHT = {
    MATCHING_MATRIX = { mfr = "LUMI", model = "lumi.light.acn004" },
    PARAMETERS = {
      ["stse.restorePowerState"] = function(device, value)
        return cluster_base.write_manufacturer_specific_attribute(device, 0xFCC0,
          0x0201, 0x115F, data_types.Boolean, value)
      end,
      ["stse.turnOffIndicatorLight"] = function(device, value)
        return cluster_base.write_manufacturer_specific_attribute(device, 0xFCC0,
          0x0203, 0x115F, data_types.Boolean, value)
      end,
      ["stse.lightFadeInTimeInSec"] = function(device, value)
        local raw_value = value * 10 -- value unit: 1sec, transition time unit: 100ms
        return clusters.Level.attributes.OnTransitionTime:write(device, raw_value)
      end,
      ["stse.lightFadeOutTimeInSec"] = function(device, value)
        local raw_value = value * 10 -- value unit: 1sec, transition time unit: 100ms
        return clusters.Level.attributes.OffTransitionTime:write(device, raw_value)
      end
    }
  },
  AQARA_LIGHT_BULB = {
    MATCHING_MATRIX = { mfr = "Aqara", model = "lumi.light.acn014" },
    PARAMETERS = {
      ["stse.restorePowerState"] = function(device, value)
        return cluster_base.write_manufacturer_specific_attribute(device, 0xFCC0,
          0x0201, 0x115F, data_types.Boolean, value)
      end
    }
  },
  POWER_ON_STATE = {
    MATCHING_MATRIX = {
        { mfr = "IKEA of Sweden", model = "TRADFRIbulbE14WSglobeopal470lm" },
        { mfr = "IKEA of Sweden", model = "TRADFRI bulb E27 WW 806lm" },
        { mfr = "IKEA of Sweden", model = "TRADFRI bulb E27 WW globe 806lm" },
        { mfr = "IKEA of Sweden", model = "TRADFRI bulb E27 CWS opal 600lm" },
        { mfr = "IKEA of Sweden", model = "TRADFRIbulbE27WSglobeopal1055lm" },
        { mfr = "IKEA of Sweden", model = "TRADFRI bulb GU10 WW 400lm" },
        { mfr = "IKEA of Sweden", model = "TRADFRI Driver 30W" },
        { mfr = "Signify Netherlands B.V.", model = "LCA008" },
        { mfr = "Signify Netherlands B.V.", model = "LWA009" },
        { mfr = "SONOFF", model = "ZBMINI-L" },
    },
    PARAMETERS = {
      ["powerOnState"] = function(device, value)
        log.debug("power on state: "..value)
        return OnOff.attributes.StartUpOnOff:write(device, POWER_ON_VALUES[value])
      end
    }
  },
}
local preferences = {}

preferences.update_preferences = function(driver, device, args)
  local prefs = preferences.get_device_parameters(device)
  if prefs ~= nil then
    for id, value in pairs(device.preferences) do
      if not (args and args.old_st_store) or (args.old_st_store.preferences[id] ~= value and prefs and prefs[id]) then
        local message = prefs[id](device, value)
        device:send(message)
      end
    end
  end
end

local device_in_matching_matrix = function(zigbee_device, matching_matrix)
  for _, matching_device in pairs(matching_matrix) do
    if zigbee_device:get_manufacturer() == matching_device.mfr
        and zigbee_device:get_model() == matching_device.model then
      return true
    end
  end
  return false
end

preferences.get_device_parameters = function(zigbee_device)
  for _, device in pairs(devices) do
    if device_in_matching_matrix(zigbee_device, device.MATCHING_MATRIX) then
      return device.PARAMETERS
    end
  end
  return nil
end

return preferences
