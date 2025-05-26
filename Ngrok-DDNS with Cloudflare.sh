#!/bin/bash

# --- CLOUDFLARE CONFIGURATION ---
CF_ZONE_ID="YOUR_ZONE_ID"             # Cloudflare Zone ID
CF_RECORD_ID="YOUR_RECORD_ID"         # Cloudflare DNS record ID to update
CF_AUTH_EMAIL="your@email.com"        # Cloudflare account email
CF_AUTH_KEY="YOUR_API_KEY"            # Cloudflare API key
CF_DOMAIN="your.subdomain.com"        # DNS record (subdomain) to update

# --- NGROK CONFIGURATION ---
NGROK_PROTO="tcp"                     # Ngrok protocol: tcp, http, https, etc.
LOCAL_PORT=25565                      # Local port to expose

# --- Start ngrok in the background ---
echo "[*] Starting ngrok ($NGROK_PROTO) on local port $LOCAL_PORT..."
ngrok $NGROK_PROTO $LOCAL_PORT > /dev/null &

# Wait for ngrok to initialize and expose the local API
sleep 5

# Retrieve the active ngrok tunnel URL for the chosen protocol
NGROK_TUNNEL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r ".tunnels[] | select(.proto==\"$NGROK_PROTO\") | .public_url")

if [[ -z "$NGROK_TUNNEL" ]]; then
  echo "[!] No active $NGROK_PROTO ngrok tunnel found. Make sure ngrok is running properly."
  exit 1
fi

# Extract hostname and port for TCP; for HTTP/HTTPS, only the hostname
if [[ "$NGROK_PROTO" == "tcp" ]]; then
  HOST=$(echo "$NGROK_TUNNEL" | sed 's/tcp:\/\///' | cut -d':' -f1)
  PORT=$(echo "$NGROK_TUNNEL" | sed 's/tcp:\/\///' | cut -d':' -f2)
  FULL_ADDR="$HOST:$PORT"
else
  # For http/https, get only the hostname from the full URL
  HOST=$(echo "$NGROK_TUNNEL" | sed -E 's#https?://([^/]+).*#\1#')
  FULL_ADDR="$NGROK_TUNNEL"
fi

echo "[*] Found ngrok tunnel: $FULL_ADDR"

# --- Update Cloudflare DNS CNAME record ---
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
  echo "[+] DNS updated successfully."
  echo "→ Public address: $FULL_ADDR"
else
  echo "[!] DNS update failed: $RESPONSE"
fi
