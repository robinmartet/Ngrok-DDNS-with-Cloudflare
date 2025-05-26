#!/bin/bash

# --- CONFIGURATION CLOUDLARE ---
CF_ZONE_ID="TON_ZONE_ID"
CF_RECORD_ID="TON_RECORD_ID"
CF_AUTH_EMAIL="ton@email.com"
CF_AUTH_KEY="TA_CLE_API"
CF_DOMAIN="mc.tondomaine.com"  # Sous-domaine à mettre à jour

# --- CONFIGURATION MINECRAFT ---
LOCAL_PORT=25565

# --- Lancer ngrok TCP en arrière-plan ---
echo "[*] Démarrage de ngrok sur le port $LOCAL_PORT ..."
ngrok tcp $LOCAL_PORT > /dev/null &

# Attendre que ngrok démarre et expose l'API locale
sleep 5

# Récupérer le tunnel TCP actif (hostname et port)
NGROK_TUNNEL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="tcp") | .public_url')

if [[ -z "$NGROK_TUNNEL" ]]; then
  echo "[!] Aucun tunnel TCP ngrok trouvé, vérifie que ngrok fonctionne."
  exit 1
fi

# Extraire hostname et port (ex: tcp://0.tcp.ngrok.io:25565)
HOST=$(echo "$NGROK_TUNNEL" | sed 's/tcp:\/\///' | cut -d':' -f1)
PORT=$(echo "$NGROK_TUNNEL" | sed 's/tcp:\/\///' | cut -d':' -f2)

echo "[*] Tunnel ngrok trouvé : $HOST:$PORT"

# --- Mettre à jour l'enregistrement CNAME Cloudflare ---
echo "[*] Mise à jour DNS Cloudflare : $CF_DOMAIN → $HOST"

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
  echo "[+] DNS mis à jour avec succès."
  echo "→ Tes joueurs peuvent se connecter avec l’adresse : $CF_DOMAIN:$PORT"
else
  echo "[!] Erreur lors de la mise à jour DNS : $RESPONSE"
fi
