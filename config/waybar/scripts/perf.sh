#!/bin/sh
# Waybar custom/perf: gauge icon in the bar, one metric per line in the tooltip.
# CPU usage is measured over a short window each run; CPU temp from coretemp, GPU from nvidia-smi.
read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat; sleep 0.5; read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
b1=$((u1+n1+s1+w1+q1+sq1)); b2=$((u2+n2+s2+w2+q2+sq2)); t1=$((b1+i1)); t2=$((b2+i2))
cpu=$(( (b2-b1)*100 / (t2-t1) ))
for h in /sys/class/hwmon/hwmon*; do [ "$(cat $h/name)" = coretemp ] && ctemp=$(( $(cat $h/temp1_input) / 1000 )); done
mt=$(awk '/MemTotal/{print $2}' /proc/meminfo); ma=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
mem=$(awk "BEGIN{printf \"%.1f / %.0f GiB\", ($mt-$ma)/1048576, $mt/1048576}")
gpu_line=""
g=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
if [ -n "$g" ]; then
  IFS=', ' read -r gu gm gt gtemp <<EOT
$g
EOT
  gmem=$(awk "BEGIN{printf \"%.1f / %.0f GiB\", $gm/1024, $gt/1024}")
  gpu_line="\n───────────────────\nGPU 󰔏 : ${gtemp} °C\nGPU usage: ${gu} %\nGPU mem: ${gmem}"
fi
class=""; [ "$cpu" -ge 80 ] && class="high"
printf '{"text":"","tooltip":"CPU 󰔏 : %s °C\\nCPU usage: %s %%\\nMem: %s%s","class":"%s"}\n' "$ctemp" "$cpu" "$mem" "$gpu_line" "$class"
