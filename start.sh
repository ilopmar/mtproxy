#!/bin/bash

if [ -z "${SECRET_KEY}" ]; then
  echo "Error: SECRET_KEY environment variable is not set. Generate a key with:"
  echo " $ head -c 16 /dev/urandom | xxd -ps"
  exit 1
fi

# Fetch the private IP address of the container
CONTAINER_PRIVATE_IP=$(ip -4 addr show | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | grep -v '127.0.0.1' | head -n 1)
CALCULATED_PUBLIC_IP=$(curl -s ifconfig.me)

# Use environment variables if set, otherwise use the fetched IP
PRIVATE_IP=${PRIVATE_IP:-$CONTAINER_PRIVATE_IP}
PUBLIC_IP=${PUBLIC_IP:-$CALCULATED_PUBLIC_IP}

echo ""
echo "============ MTProxy ============"
echo "Using PRIVATE_IP: $PRIVATE_IP"
echo "Using PUBLIC_IP: $PUBLIC_IP"
echo ""
echo " Use the following proxy in Telegram: "
echo "  tg://proxy?server=${PUBLIC_IP}&port=8443&secret=${SECRET_KEY}"
echo "============ MTProxy ============"
echo ""

/opt/MTProxy/mtproto-proxy -u mtproxy -p 8888 -H 8443 -S "${SECRET_KEY}" --aes-pwd proxy-secret proxy-multi.conf -M 1 --http-stats --nat-info "$PRIVATE_IP:$PUBLIC_IP"
