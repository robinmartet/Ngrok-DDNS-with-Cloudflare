# Ngrok-DDNS with Cloudflare

This Bash script automates the creation of an Ngrok tunnel and dynamically updates a Cloudflare DNS record.  
It allows you to expose a local service (such as a Minecraft server) to the internet through a custom domain name, automatically syncing the public Ngrok URL with your Cloudflare DNS.

---

## Features

- Automatically starts an Ngrok tunnel on a configurable local port (default: 25565 for Minecraft).
- Supports Ngrok protocols: `tcp`, and `http`.
- Retrieves the public Ngrok URL dynamically via the local Ngrok API.
- Updates a Cloudflare DNS CNAME record to point to the Ngrok tunnel address.
- Displays the final public address accessible to clients.

---

## Prerequisites

- A domain managed by Cloudflare.
- A Cloudflare API key (Global API Key or API Token with DNS edit permissions).
- Ngrok installed and accessible from the command line.
- The `jq` command-line JSON processor installed.

---

## Installation

### 1. Clone this repository or create the script file

Create a file named `ngrok-cloudflare-ddns.sh` and paste the script contents into it.

### 2. Install `jq`

On Ubuntu/Debian, install `jq` with:

```bash
sudo apt-get update
sudo apt-get install jq
```
### 3. Install `Ngrok`

On Ubuntu/Debian, install `Ngrok` with:

```bash
wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O /tmp/ngrok.zip && unzip -q /tmp/ngrok.zip -d /tmp && sudo mv /tmp/ngrok /usr/local/bin/ngrok && sudo chmod +x /usr/local/bin/ngrok && rm /tmp/ngrok.zip
```
### 4. Configure Ngrok authentication token

Sign up on ngrok.com if you don’t have an account, then get your authentication token and run:

```bash
ngrok authtoken YOUR_NGROK_AUTHTOKEN
```
This step enables your Ngrok client to use advanced features and keeps tunnels associated with your account.

### 5. Script Configuration

Open the script file and edit the following variables at the top:

```bash
CF_ZONE_ID="YOUR_CLOUDFLARE_ZONE_ID"          # Your Cloudflare zone ID
CF_RECORD_ID="YOUR_CLOUDFLARE_RECORD_ID"      # Your DNS record ID to update
CF_AUTH_EMAIL="your@email.com"                 # Your Cloudflare account email
CF_AUTH_KEY="YOUR_CLOUDFLARE_API_KEY"          # Your Cloudflare API key
CF_DOMAIN="mc.yourdomain.com"                  # The DNS record (subdomain) to update
NGROK_PROTO="tcp"                              # Ngrok protocol: tcp, http, or https
LOCAL_PORT=25565                               # Local port to expose (Minecraft default)
```
You can obtain CF_ZONE_ID and CF_RECORD_ID via the Cloudflare dashboard or API.

Ensure the DNS record for your subdomain exists in your Cloudflare DNS zone (CNAME)

---

## Usage

### 6. Make the script executable:

```bash
chmod +x ngrok-cloudflare-ddns.sh
```
### 7. Run the script:

```bash
./ngrok-cloudflare-ddns.sh
```
The script will:

Start an Ngrok tunnel with your specified settings.

Retrieve the public Ngrok address via the Ngrok API.

Update the DNS record on Cloudflare to point to the Ngrok hostname.

Display the public address for client connections.

---

## Important Notes About Ports

DNS records do not handle ports.

If Ngrok assigns a different remote port than your service’s default (e.g., not 25565 for Minecraft), clients will have to specify the port explicitly when connecting:
mc.yourdomain.com:PORT.

To avoid this, you must configure Ngrok to reserve the fixed port 25565, which requires a paid Ngrok plan.

Alternatively, you can set up a local TCP proxy (using tools like haproxy or socat) that listens on port 25565 and forwards traffic to the dynamic Ngrok port.

---

## Automation

To run this script automatically on startup or continuously, consider creating a systemd service or cron job.
If you want, I can provide an example systemd unit file.

---

## Contributing

Feel free to submit issues or pull requests for bug fixes or feature requests.
