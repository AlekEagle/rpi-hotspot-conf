#!/bin/sh
# This is a bash script lol.

# Function Declarations

debug() {
  if [ "$DEBUG" = true ]; then
    if [ "$1" = '' ]; then
      echo "[\e[32mDEBUG\e[0m] $(cat /dev/stdin)"
    else
      echo "[\e[32mDEBUG\e[0m] $1"
    fi
  fi
}

log() {
  if [ "$1" = '' ]; then 
    echo "[\e[36mLOG\e[0m] $(cat /dev/stdin)"
  else
    echo "[\e[36mLOG\e[0m] $1"
  fi
}

error() {
  if [ "$1" = '' ]; then 
    echo "[\e[31mERROR\e[0m] $(cat /dev/stdin)"
  else
    echo "[\e[31mERROR\e[0m] $1"
  fi
}

warn() {
  if [ "$1" = '' ]; then 
    echo "[\e[33mWARN\e[0m] $(cat /dev/stdin)"
  else
    echo "[\e[33mWARN\e[0m] $1"
  fi
}

# Script Body

clear

# Banner
echo "\e[1;32m   .~~.   .~~.\e[0m"
echo "\e[1;32m  '. \ ' ' / .'\e[0m"
echo "\e[1;31m   .~ .~~~..~.\e[0m"
echo "\e[1;31m  : .~.'~'.~. :\e[0m"
echo "\e[1;31m ~ (   ) (   ) ~\e[0m"
echo "\e[1;31m( : '~'.~.'~' : )\e[0m"
echo "\e[1;31m ~ .~ (   ) ~. ~\e[0m"
echo "\e[1;31m  (  : '~' :  )\e[0m Raspberry Pi Hotspot Setup"
echo "\e[1;31m   '~ .~~~. ~'\e[0m"
echo "\e[1;31m       '~'\e[0m"

# Check if we're running as root
if [ "$(id -u)" -ne 0 ]; then
  error "This script must be run as root!"
  exit 1
fi

if [ "$NO_MODIFY" = true ]; then
  warn "Skipping all modification steps!"
fi

log "Installing dependencies... this may take a while (ifupdown, dnsmasq, hostapd, bridge-utils, net-tools)"
if [ "$NO_MODIFY" = true ]; then
  log "Skipping installation!"
else
  apt-get update | debug
  apt-get install -y ifupdown dnsmasq hostapd bridge-utils net-tools | debug
fi

echo ""
log "Making backups of existing config files..."

if [ "$NO_MODIFY" = true ]; then
  log "Skipping backup!"
else
  cp /etc/network/interfaces /etc/network/interfaces.bak | debug 
  cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak | debug
  cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.bak | debug
fi


echo ""
log "Copying our config files..."

if [ "$NO_MODIFY" = true ]; then
  log "Skipping copy!"
else
  cp config/interfaces /etc/network/interfaces | debug
  cp config/dnsmasq.conf /etc/dnsmasq.conf | debug
  cp config/hostapd.conf /etc/hostapd/hostapd.conf | debug
fi

echo ""
log "Configuring interfaces..."
if [ "$NO_MODIFY" = true ]; then
  log "Skipping configuration!"
else
  ifconfig br0 down | debug
  ifconfig wlan0 down | debug
  ifconfig br0 up | debug
  ifconfig wlan0 up | debug
fi

echo ""
log "Enable IP forwarding..."
if [ "$NO_MODIFY" = true ]; then
  log "Skipping configuration!"
else
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE | debug
  iptables-save > /etc/iptables.ipv4.nat | debug
  echo "iptables-restore < /etc/iptables.ipv4.nat" >> /etc/rc.local | debug
  chmod +x /etc/rc.local | debug
  echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf | debug
  echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf | debug
  sysctl -p | debug
fi

echo ""
log "Configuring services... this may take a while (dnsmasq, hostapd)"

echo ""
log "Unmasking hostapd..."
if [ "$NO_MODIFY" = true ]; then
  log "Skipping unmask hostapd!"
else
  systemctl unmask hostapd | debug
fi

echo ""
log "Enabling hostapd and dnsmasq..."
if [ "$NO_MODIFY" = true ]; then
  log "Skipping enabling hostapd and dnsmasq!"
else
  systemctl enable hostapd | debug
  systemctl enable dnsmasq | debug
fi

echo ""
log "Starting hostapd and dnsmasq..."
if [ "$NO_MODIFY" = true ]; then
  log "Skipping starting hostapd and dnsmasq!"
else
  systemctl start hostapd | debug
  systemctl start dnsmasq | debug
fi

echo ""
echo ""
log "Done! The Raspberry Pi's WiFi network is called 'Raspberry Pi Hotspot' and the password is 'raspberry'."
log "The Hotspot will automatically start when the Raspberry Pi is booted."
log "A configuration panel is coming soon!"
warn "Please make sure to change the password to something more secure! To change it, edit the /etc/hostapd/hostapd.conf file."
echo ""
echo ""