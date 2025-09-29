#!/bin/sh

CONF="/etc/wireguard/wgcf.conf"
IFACE="cloudflare"

# B1: tạo thư mục wireguard nếu chưa có
mkdir -p /etc/wireguard

# B2: chạy warp.sh để tạo file config
/root/warp.sh > "$CONF" || {
    echo "❌ warp.sh lỗi, không tạo được config"
    exit 1
}

# B3: xoá config cũ trong UCI
uci -q delete network.$IFACE
uci -q delete network.wireguard_$IFACE

# B4: lấy PrivateKey + Address từ file
PRIVATE_KEY=$(grep '^PrivateKey' "$CONF" | cut -d= -f2 | tr -d ' ')
ADDRESSES=$(grep '^Address' "$CONF" | cut -d= -f2 | tr -d ' ')

uci set network.$IFACE="interface"
uci set network.$IFACE.proto="wireguard"
uci set network.$IFACE.private_key="$PRIVATE_KEY"
uci set network.$IFACE.mtu="1280"

for ip in $(echo $ADDRESSES | tr ',' ' '); do
    uci add_list network.$IFACE.addresses="$ip"
done

# B5: lấy Peer info
uci set network.wireguard_$IFACE="wireguard_$IFACE"
PUBLIC_KEY=$(grep '^PublicKey' "$CONF" | cut -d= -f2 | tr -d ' ')
uci set network.wireguard_$IFACE.public_key="$PUBLIC_KEY"

ENDPOINT=$(grep '^Endpoint' "$CONF" | cut -d= -f2- | tr -d ' ')
uci set network.wireguard_$IFACE.endpoint_host="${ENDPOINT%:*}"
uci set network.wireguard_$IFACE.endpoint_port="${ENDPOINT##*:}"

uci set network.wireguard_$IFACE.persistent_keepalive="25"
uci add_list network.wireguard_$IFACE.allowed_ips="0.0.0.0/0"
uci add_list network.wireguard_$IFACE.allowed_ips="::/0"

# B6: commit thay đổi
uci commit network

echo "✅ Hoàn tất: config đã import vào UCI"
echo "👉 Bạn có thể enable bằng: ifup $IFACE"
