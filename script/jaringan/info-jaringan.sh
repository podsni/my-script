#!/bin/bash

# --- Mencari Informasi Jaringan Secara Otomatis ---

# 1. Dapatkan nama interface jaringan utama (misal: eth0 atau wlan0)
INTERFACE=$(ip route | grep default | awk '{print $5}')

# Jika tidak ada interface, keluar.
if [ -z "$INTERFACE" ]; then
  echo "Error: Tidak dapat menemukan interface jaringan default."
  exit 1
fi

# 2. Dapatkan Alamat IP dan CIDR dari interface tersebut
IP_CIDR=$(ip -4 addr show "$INTERFACE" | grep "inet" | awk '{print $2}')
ADDRESS=$(echo "$IP_CIDR" | cut -d'/' -f1)
CIDR=$(echo "$IP_CIDR" | cut -d'/' -f2)

# 3. Dapatkan Gateway
GATEWAY=$(ip route | grep default | awk '{print $3}')

# 4. Dapatkan DNS Server pertama dari /etc/resolv.conf
DNS=$(grep "^nameserver" /etc/resolv.conf | head -n1 | awk '{print $2}')

# 5. Konversi CIDR ke Netmask (untuk format 255.255.255.0)
case $CIDR in
"8") NETMASK="255.0.0.0" ;;
"16") NETMASK="255.255.0.0" ;;
"24") NETMASK="255.255.255.0" ;;
"32") NETMASK="255.255.255.255" ;;
*) NETMASK="Tidak diketahui (CIDR: /$CIDR)" ;;
esac

# --- Tampilkan Hasil ---
echo "Address=$ADDRESS"
echo "Gateway=$GATEWAY"
echo "Netmask=$NETMASK"
echo "DNS=$DNS"