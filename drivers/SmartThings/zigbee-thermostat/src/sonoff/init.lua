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

local clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"

local PowerConfiguration = clusters.PowerConfiguration
local Thermostat = clusters.Thermostat
local OnOff = clusters.OnOff

local ThermostatMode = capabilities.thermostatMode
local Switch = capabilities.switch

local SONOFF_THERMOSTAT_FINGERPRINTS = {
  {
    mfr = "SONOFF",
    model = "TRVZB",
  },
}

local SUPPORTED_MODES = {
  ThermostatMode.thermostatMode.heat.NAME,
  ThermostatMode.thermostatMode.auto.NAME,
  ThermostatMode.thermostatMode.off.NAME,
}

local is_sonoff_thermostat = function(opts, driver, device)
  for _, fingerprint in ipairs(SONOFF_THERMOSTAT_FINGERPRINTS) do
    if device:get_manufacturer() == fingerprint.mfr and device:get_model() == fingerprint.model then
      return true
    end
  end
  return false
end

local device_added = function(driver, device)
  device:emit_event(ThermostatMode.supportedThermostatModes(SUPPORTED_MODES, {
    visibility = { displayed = false }
  }))
end

local do_refresh = function(driver, device)
  local attributes = {
    OnOff.attributes.OnOff,
    Thermostat.attributes.OccupiedHeatingSetpoint,
    Thermostat.attributes.LocalTemperature,
    Thermostat.attributes.SystemMode,
    Thermostat.attributes.ThermostatRunningState,
    PowerConfiguration.attributes.BatteryPercentageRemaining,
  }
  for _, attribute in pairs(attributes) do
    device:send(attribute:read(device))
  end
end

local sonoff_thermostat = {
  NAME = "SONOFF Thermostat",
  capability_handlers = {
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = do_refresh
    },
  },
  lifecycle_handlers = {
    added = device_added,
  },
  can_handle = is_sonoff_thermostat,
}

return sonoff_thermostat
