#!/bin/sh
# Waybar custom/gpu: NVIDIA utilisation, VRAM, temperature, power (needs nvidia-smi)
out=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader,nounits 2>/dev/null) || { echo '{"text":"n/a","tooltip":"nvidia-smi failed"}'; exit 0; }
IFS=', ' read -r util used total temp power <<EOT
$out
EOT
usedg=$(awk "BEGIN{printf \"%.1f\", $used/1024}"); totalg=$(awk "BEGIN{printf \"%.0f\", $total/1024}")
class=""; [ "$util" -ge 80 ] && class="high"
printf '{"text":"%s%% %sG","tooltip":"GPU %s%%  VRAM %s/%s GiB  %s°C  %s W","class":"%s","percentage":%s}\n' "$util" "$usedg" "$util" "$usedg" "$totalg" "$temp" "$power" "$class" "$util"
