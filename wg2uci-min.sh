#!/bin/sh

CONF="$1"
IFACE="cloudflare"

# Xoá config cũ (nếu có)
uci -q delete network.$IFACE
uci -q delete network.wireguard_$IFACE

# Interface
uci set network.$IFACE="interface"
uci set network.$IFACE.proto="wireguard"

PRIVATE_KEY=$(grep '^PrivateKey' "$CONF" | cut -d= -f2 | tr -d ' ')
ADDRESSES=$(grep '^Address' "$CONF" | cut -d= -f2 | tr -d ' ')

uci set network.$IFACE.private_key="$PRIVATE_KEY"
for ip in $(echo $ADDRESSES | tr ',' ' '); do
    uci add_list network.$IFACE.addresses="$ip"
done

# Peer
uci set network.wireguard_$IFACE="wireguard_$IFACE"
PUBLIC_KEY=$(grep '^PublicKey' "$CONF" | cut -d= -f2 | tr -d ' ')
uci set network.wireguard_$IFACE.public_key="$PUBLIC_KEY"

uci commit network
