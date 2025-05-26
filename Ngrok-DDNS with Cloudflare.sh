#!/usr/bin/env bash

# --- CLOUDFLARE CONFIGURATION ---
CF_ZONE_ID="YOUR_ZONE_ID"             # Cloudflare Zone ID
CF_RECORD_ID="YOUR_RECORD_ID"         # Cloudflare DNS record ID to update
CF_AUTH_EMAIL="your@email.com"        # Cloudflare account email
CF_AUTH_KEY="YOUR_API_KEY"            # Cloudflare API key
CF_DOMAIN="your.subdomain.com"        # DNS record (subdomain) to update

# --- NGROK CONFIGURATION ---
NGROK_PROTO="http"                    # ngrok protocol: tcp, http, https
LOCAL_PORT=9000                      # Local port to expose

# --- Start ngrok in the background ---
echo "[*] Starting ngrok ($NGROK_PROTO) on local port $LOCAL_PORT..."
ngrok $NGROK_PROTO $LOCAL_PORT --log=stdout > ngrok.log 2>&1 &

sleep 15  # Wait ngrok to initialize

echo "[*] Retrieving ngrok public URL for protocol '$NGROK_PROTO'..."

if [[ "$NGROK_PROTO" == "tcp" ]]; then
  NGROK_TUNNEL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="tcp") | .public_url')
  if [[ -z "$NGROK_TUNNEL" ]]; then
    echo "[!] No active TCP ngrok tunnel found."
    exit 1
  fi
  HOST=$(echo "$NGROK_TUNNEL" | sed 's|tcp://||' | cut -d':' -f1)
  PORT=$(echo "$NGROK_TUNNEL" | sed 's|tcp://||' | cut -d':' -f2)
  FULL_ADDR="$HOST:$PORT"

elif [[ "$NGROK_PROTO" == "http" || "$NGROK_PROTO" == "https" ]]; then
  NGROK_TUNNEL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r ".tunnels[] | select(.proto==\"$NGROK_PROTO\") | .public_url")

  # If not found and proto is http, fallback to https tunnel
  if [[ -z "$NGROK_TUNNEL" && "$NGROK_PROTO" == "http" ]]; then
    NGROK_TUNNEL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="https") | .public_url')
    NGROK_PROTO="https"
  fi

  if [[ -z "$NGROK_TUNNEL" ]]; then
    echo "[!] No active $NGROK_PROTO ngrok tunnel found."
    exit 1
  fi

  HOST=$(echo "$NGROK_TUNNEL" | sed -E 's#https?://([^/:]+).*#\1#')
  FULL_ADDR="$NGROK_TUNNEL"

else
  echo "[!] Protocol '$NGROK_PROTO' not supported."
  exit 1
fi

echo "[*] Found ngrok tunnel: $FULL_ADDR"

echo "[*] Updating Cloudflare DNS: $CF_DOMAIN → $HOST"

RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID" \
  -H "X-Auth-Email: $CF_AUTH_EMAIL" \
  -H "X-Auth-Key: $CF_AUTH_KEY" \
  -H "Content-Type: application/json" \
  --data '{
    "type":"CNAME",
    "name":"'"$CF_DOMAIN"'",
    "content":"'"$HOST"'",
    "ttl":120,
    "proxied":false
  }')

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [[ "$SUCCESS" == "true" ]]; then
  if [[ "$NGROK_PROTO" == "tcp" ]]; then
    echo "[+] DNS updated successfully."
    echo "→ Public address: $CF_DOMAIN:$PORT"
  else
    echo "[+] DNS updated successfully."
    echo "→ Public address: https://$CF_DOMAIN"
  fi
else
  echo "[!] DNS update failed: $RESPONSE"
  exit 1
fi
