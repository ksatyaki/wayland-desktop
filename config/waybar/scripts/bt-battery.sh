#!/bin/sh
# Battery level of the connected Bluetooth audio device, as waybar JSON.
#
# BlueZ publishes a level on org.bluez.Battery1 only for devices that report one
# (GATT Battery Service, or the HFP battery indicators PipeWire forwards through
# BlueZ's battery-provider API). That provider API is behind BlueZ's experimental
# flag, so headsets that report over HFP need this in /etc/bluetooth/main.conf:
#     Experimental = true
# With no connected device, or none reporting a level, this prints empty text and
# waybar hides the module.
#
# Audio devices come first so a headset wins over a phone or a mouse that also
# reports a battery; among those, the first connected one is used.
set -eu

busctl --system --json=short call \
    org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null |
jq -c '
    [ .data[0] | to_entries[]
      | select(.value["org.bluez.Device1"].Connected.data == true)
      | select(.value["org.bluez.Battery1"])
      | { name: .value["org.bluez.Device1"].Alias.data,
          icon: (.value["org.bluez.Device1"].Icon.data // ""),
          pct:  .value["org.bluez.Battery1"].Percentage.data } ]
    | sort_by(if (.icon | startswith("audio-")) then 0 else 1 end)
    | if length == 0 then { text: "" }
      else .[0] as $d
        | { text: "\($d.pct)%",
            percentage: $d.pct,
            tooltip: "\($d.name): \($d.pct)% battery",
            class: (if $d.pct <= 15 then "critical" elif $d.pct <= 30 then "warning" else "" end) }
      end
' 2>/dev/null || echo '{"text":""}'
