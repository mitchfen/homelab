#!/bin/bash
set -e

# Function to format bytes to human-readable format
format_bytes() {
  local bytes=$1
  if [ $bytes -lt 1024 ]; then
    echo "${bytes}B"
  elif [ $bytes -lt 1048576 ]; then
    echo "$(( bytes / 1024 ))KB"
  elif [ $bytes -lt 1073741824 ]; then
    echo "$(( bytes / 1048576 ))MB"
  else
    echo "$(( bytes / 1073741824 ))GB"
  fi
}

total_space_saved=0

echo ""
echo "########### apt update... ###########"
echo ""
sudo apt update

echo ""
echo "########### apt upgrade... ###########"
echo ""
sudo apt dist-upgrade

echo ""
echo "########### apt cleanup... ###########"
echo ""
apt_before=$(du -sb /var/cache/apt /var/lib/apt/lists 2>/dev/null | awk '{sum+=$1} END {print sum}')
sudo apt autoclean && sudo apt autoremove -y
apt_after=$(du -sb /var/cache/apt /var/lib/apt/lists 2>/dev/null | awk '{sum+=$1} END {print sum}')
apt_saved=$((apt_before - apt_after))
total_space_saved=$((total_space_saved + apt_saved))
echo "  Freed: $(format_bytes $apt_saved)"

echo ""
echo "########### npm cache clean... ###########"
echo ""
npm_before=$(du -sb ~/.npm 2>/dev/null | awk '{print $1}' || echo 0)
npm cache clean --force
npm_after=$(du -sb ~/.npm 2>/dev/null | awk '{print $1}' || echo 0)
npm_saved=$((npm_before - npm_after))
total_space_saved=$((total_space_saved + npm_saved))
echo "  Freed: $(format_bytes $npm_saved)"

echo ""
echo "########### go clean... ###########"
echo ""
go_before=$(du -sb ~/go/pkg/mod 2>/dev/null | awk '{print $1}' || echo 0)
go clean -modcache
go_after=$(du -sb ~/go/pkg/mod 2>/dev/null | awk '{print $1}' || echo 0)
go_saved=$((go_before - go_after))
total_space_saved=$((total_space_saved + go_saved))
echo "  Freed: $(format_bytes $go_saved)"

echo ""
echo "########### Update CoPilot... ###########"
echo ""
sudo npm update -g @github/copilot

echo ""
echo "✓ All updates completed successfully!"
echo "✓ Total space saved: $(format_bytes $total_space_saved)"
echo ""
