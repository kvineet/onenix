# NixOS on Azure with nixos-anywhere

This runbook creates a temporary Ubuntu VM in an Azure VNet and replaces its
operating system with the `kv-vpc` NixOS configuration by using
`nixos-anywhere`.

The installation is destructive. Disko will erase the disk configured as
`/dev/sda` in `disk-config.nix`. Verify the Azure OS disk device before running
the installation.

## 1. Prerequisites

The workstation needs:

- Nix with flakes enabled
- An Azure subscription
- An SSH key
- Permission to create Azure network and compute resources

Enter a shell containing the Azure CLI if it is not already installed:

```bash
nix shell nixpkgs#azure-cli
```

Sign in and select the intended subscription:

```bash
az login
az account list --output table
az account set --subscription "SUBSCRIPTION_NAME_OR_ID"
az account show --output table
```

Verify that the SSH public key exists:

```bash
test -f "$HOME/.ssh/id_ed25519.pub"
```

Generate one if necessary:

```bash
ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519"
```

## 2. Define deployment values

Run these commands in the same shell used for the remaining Azure commands:

```bash
export LOCATION="centralindia"
export RESOURCE_GROUP="kv-vpc"
export VNET="kv-vpc-vnet"
export SUBNET="gateway"
export NSG="kv-vpc-nsg"
export PUBLIC_IP="kv-vpc-ip"
export NIC="kv-vpc-nic"
export VM="kv-vpc"
export ADMIN_USER="azureuser"
export SSH_PUBLIC_KEY="$HOME/.ssh/id_ed25519.pub"
```

Set the public CIDR from which SSH should be accepted. Use a single-host `/32`
CIDR when the workstation has a stable public address:

```bash
export ADMIN_CIDR="203.0.113.10/32"
```

Do not use the example address above. Determine the workstation's actual
public address and replace it.

## 3. Create the resource group and VNet

```bash
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET" \
  --address-prefixes "10.200.0.0/16" \
  --subnet-name "$SUBNET" \
  --subnet-prefixes "10.200.1.0/24"
```

## 4. Create the Network Security Group

Create the NSG and permit SSH only from the administrator address:

```bash
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NSG"

az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG" \
  --name "AllowSSH" \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "$ADMIN_CIDR" \
  --destination-port-ranges 22
```

Do not expose NFS port 2049 to the Internet.

If this machine will be the publicly reachable WireGuard endpoint, also permit
UDP 51820:

```bash
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG" \
  --name "AllowWireGuard" \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Udp \
  --source-address-prefixes Internet \
  --destination-port-ranges 51820
```

Restrict the WireGuard rule to the home public CIDR when it is stable.

## 5. Create the public IP and network interface

Use a static Standard public IP so the WireGuard endpoint remains stable:

```bash
az network public-ip create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$PUBLIC_IP" \
  --sku Standard \
  --allocation-method Static

az network nic create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NIC" \
  --vnet-name "$VNET" \
  --subnet "$SUBNET" \
  --network-security-group "$NSG" \
  --public-ip-address "$PUBLIC_IP" \
  --ip-forwarding true
```

IP forwarding is needed only when this VM routes traffic for other Azure VMs,
but enabling it now avoids replacing the NIC later.

## 6. Create the temporary Ubuntu VM

Create a Generation 2 VM with standard security. Do not enable Secure Boot:

```bash
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM" \
  --nics "$NIC" \
  --image Ubuntu2404 \
  --size Standard_B2s \
  --os-disk-size-gb 30 \
  --storage-sku StandardSSD_LRS \
  --security-type Standard \
  --admin-username "$ADMIN_USER" \
  --ssh-key-values "$SSH_PUBLIC_KEY"
```

Retrieve its addresses:

```bash
export VM_IP="$(
  az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PUBLIC_IP" \
    --query ipAddress \
    --output tsv
)"

az vm show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM" \
  --show-details \
  --output table

printf 'VM public IP: %s\n' "$VM_IP"
```

## 7. Verify SSH, sudo, firmware, and disks

Wait for SSH to become available:

```bash
ssh "$ADMIN_USER@$VM_IP"
```

On the Ubuntu VM, verify passwordless sudo and UEFI boot:

```bash
sudo -n true
test -d /sys/firmware/efi
```

Inspect every block device carefully:

```bash
lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
findmnt /
```

The repository currently configures `/dev/sda` as the OS disk. Continue only
if `/dev/sda` is the persistent Azure OS disk containing the current root
filesystem.

Azure may also provide an ephemeral resource disk. Never select that disk as
the NixOS system disk. If the OS disk is not `/dev/sda`, update
`machines/kv-vpc/disk-config.nix` before continuing.

Exit the VM:

```bash
exit
```

## 8. Review the NixOS configuration

The host configuration imports:

- `virtualisation/azure-common.nix` for the Azure Linux Agent, cloud-init,
  Azure networking, Hyper-V drivers, serial console support, and disk rules
- `machines/common/configuration.nix` for the `kvineet` user, SSH keys, and
  sudo configuration
- `machines/kv-vpc/disk-config.nix` for the destructive disk layout

Evaluate the important settings before installation:

```bash
nix eval --json \
  'path:.#nixosConfigurations.kv-vpc.config' \
  --apply 'c: {
    waagent = c.services.waagent.enable;
    cloudInit = c.services.cloud-init.enable;
    cloudInitNetwork = c.services.cloud-init.network.enable;
    ssh = c.services.openssh.enable;
    hostName = c.networking.hostName;
    disk = c.disko.devices.disk.system.device;
  }'
```

Build the Disko script and complete system:

```bash
nix build \
  'path:.#nixosConfigurations.kv-vpc.config.system.build.diskoScript' \
  --no-link

nix build \
  'path:.#nixosConfigurations.kv-vpc.config.system.build.toplevel' \
  --no-link
```

`path:.` includes untracked files. After all `kv-vpc` files have been added to
Git, `.#kv-vpc` can be used instead.

## 9. Install NixOS with nixos-anywhere

Run this command from the repository root:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake 'path:.#kv-vpc' \
  "$ADMIN_USER@$VM_IP"
```

The installer will:

1. Boot a temporary NixOS environment.
2. Erase and repartition `/dev/sda`.
3. Install the `kv-vpc` NixOS configuration.
4. Reboot the Azure VM.

Do not interrupt the VM while Disko is partitioning or while NixOS is being
installed.

## 10. Reconnect after installation

The SSH host key changes when Ubuntu is replaced:

```bash
ssh-keygen -R "$VM_IP"
```

Connect using the declaratively configured NixOS user:

```bash
ssh "kvineet@$VM_IP"
```

If SSH does not return after several minutes, inspect the VM through Azure
Boot Diagnostics or the Azure Serial Console.

## 11. Verify Azure integration

On the NixOS VM:

```bash
systemctl --no-pager --full status sshd
systemctl --no-pager --full status waagent
systemctl --no-pager --full status cloud-init
cloud-init status --long
networkctl status
journalctl -b -u waagent --no-pager
```

Verify access to the Azure Instance Metadata Service:

```bash
curl \
  --silent \
  --fail \
  --header Metadata:true \
  'http://169.254.169.254/metadata/instance?api-version=2025-04-07' |
  nix shell nixpkgs#jq -c jq .
```

From the workstation, check Azure's view of the VM:

```bash
az vm get-instance-view \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM" \
  --output table
```

Reboot once to confirm the VM boots without assistance:

```bash
az vm restart \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM"
```

After the reboot, reconnect and verify that `sshd`, `waagent`, and networking
are active.

## 12. Enroll the WireGuard peers

The NixOS configurations generate each machine's WireGuard keypair at runtime:

```text
/var/lib/wireguard/private.key
/var/lib/wireguard/public.key
```

Private keys remain on their respective machines and must never be copied.
Only public keys are exchanged.

Deploy the corresponding Tardis configuration before enrollment so both
machines have generated their keypairs:

```bash
nixos-rebuild switch \
  --flake .#tardis \
  --target-host "kvineet@192.168.68.113" \
  --sudo
```

Copy Tardis's public key to the Azure VM:

```bash
ssh kvineet@192.168.68.113 \
  'sudo cat /var/lib/wireguard/public.key' |
  ssh "kvineet@$VM_IP" \
    'sudo install -D -m 0600 /dev/stdin /var/lib/wireguard/peers/tardis.public'
```

Copy the Azure VM's public key to Tardis:

```bash
ssh "kvineet@$VM_IP" \
  'sudo cat /var/lib/wireguard/public.key' |
  ssh kvineet@192.168.68.113 \
    'sudo install -D -m 0600 /dev/stdin /var/lib/wireguard/peers/kv-vpc.public'
```

Store the Azure static public endpoint on Tardis:

```bash
printf '%s:51820\n' "$VM_IP" |
  ssh kvineet@192.168.68.113 \
    'sudo install -D -m 0600 /dev/stdin /var/lib/wireguard/peers/kv-vpc.endpoint'
```

Apply the enrolled peers:

```bash
ssh "kvineet@$VM_IP" \
  'sudo systemctl restart wireguard-peer-tardis.service'

ssh kvineet@192.168.68.113 \
  'sudo systemctl restart wireguard-peer-kv-vpc.service'
```

Tardis initiates the tunnel to the Azure static public IP and sends a keepalive
every 25 seconds. Therefore, no inbound WireGuard port or port forwarding is
required on the home router.

Verify the tunnel on both machines:

```bash
ssh "kvineet@$VM_IP" 'sudo wg show'
ssh kvineet@192.168.68.113 'sudo wg show'
```

Test the tunnel addresses:

```bash
ssh kvineet@192.168.68.113 'ping -c 3 10.100.0.2'
ssh "kvineet@$VM_IP" 'ping -c 3 10.100.0.1'
```

Test access from the Azure VM to the home LAN:

```bash
ssh "kvineet@$VM_IP" 'ping -c 3 192.168.68.113'
```

Tardis enables IPv4 forwarding and source NAT from `wg0` to the home LAN.
Consequently, other home LAN devices do not need a return route for the
WireGuard or Azure VNet subnets.

Mount the Tardis NFS export over WireGuard:

```bash
ssh "kvineet@$VM_IP" \
  'sudo mkdir -p /mnt/nas && sudo mount.nfs4 -o vers=4.1 10.100.0.1:/nas /mnt/nas'
```

Because this traffic originates from a normal Linux VM and travels through
WireGuard without WSL NAT, the Tardis WireGuard NFS export can retain the
default `secure` source-port requirement.

For other Azure VMs to route through `kv-vpc`, associate an Azure route table
with their subnet and add routes using the `kv-vpc` NIC's private address as a
Virtual Appliance next hop. The NIC was created with IP forwarding enabled,
and the NixOS configuration enables IPv4 forwarding.

## 13. Configure Cloudflare Tunnel for SSH

The NixOS configuration runs a remotely managed Cloudflare Tunnel. It reads
the tunnel token from:

```text
/var/lib/cloudflared/tunnel-token
```

The token is a secret and must not be committed to Git or placed directly in
the Nix configuration.

### 13.1 Create the tunnel

In the Cloudflare Zero Trust dashboard:

1. Open **Networks > Connectors > Cloudflare Tunnels**.
2. Select **Create a tunnel**.
3. Choose the `cloudflared` connector.
4. Name the tunnel `kv-vpc`.
5. Save the generated tunnel token securely.

Only the token value is needed. Do not run the dashboard's package-install
command because NixOS manages the `cloudflared` package and systemd service.

### 13.2 Configure the public hostname

Add a public hostname to the `kv-vpc` tunnel:

```text
Subdomain: kv-vpc
Domain:    kvineet.in
Type:      SSH
URL:       localhost:22
```

The resulting hostname is:

```text
kv-vpc.kvineet.in
```

Cloudflare creates the required proxied DNS record. The tunnel makes outbound
connections, so no Cloudflare-related inbound Azure NSG port is required.

### 13.3 Create a Cloudflare Access application

In **Access > Applications**:

1. Create a **Self-hosted** application.
2. Set its hostname to `kv-vpc.kvineet.in`.
3. Add an Allow policy containing only the required users or identity groups.
4. Configure an appropriate Access session duration.

Do not create an Allow policy that permits every user.

### 13.4 Install the tunnel token

Read the token without adding it to shell history:

```bash
read -rsp 'Cloudflare tunnel token: ' CLOUDFLARE_TUNNEL_TOKEN
printf '\n'
```

Install it on `kv-vpc`:

```bash
printf '%s' "$CLOUDFLARE_TUNNEL_TOKEN" |
  ssh "kvineet@$VM_IP" \
    'sudo install -D -m 0600 /dev/stdin /var/lib/cloudflared/tunnel-token'

unset CLOUDFLARE_TUNNEL_TOKEN
```

Start and verify the connector:

```bash
ssh "kvineet@$VM_IP" \
  'sudo systemctl restart cloudflared-kv-vpc.service'

ssh "kvineet@$VM_IP" \
  'systemctl --no-pager --full status cloudflared-kv-vpc.service'

ssh "kvineet@$VM_IP" \
  'journalctl -u cloudflared-kv-vpc.service -n 50 --no-pager'
```

The Cloudflare dashboard should show the tunnel as healthy.

### 13.5 Configure and test the SSH client

The repository's Home Manager Cloudflare module configures:

- `cloudflared access ssh` as the SSH proxy
- User `kvineet`
- The existing SSH keys configured for the `kvineet` account

Apply the relevant Home Manager configuration, then connect:

```bash
ssh kv-vpc.kvineet.in
```

The first connection opens a browser for Cloudflare Access authentication.
After authentication, SSH uses the workstation's existing SSH key to connect
to the local `kvineet` account through the tunnel.

Verify the effective SSH configuration if troubleshooting:

```bash
ssh -G kv-vpc.kvineet.in |
  grep -E '^(user|proxycommand|identityfile) '
```

Keep the Azure NSG SSH rule restricted to the administrator's public `/32`
address as a recovery path until Cloudflare access has been tested after a
reboot. It can then be removed if Cloudflare Tunnel is intended to be the only
SSH path, although direct SSH is still useful for disaster recovery.

To rotate the tunnel token, rotate it in Cloudflare, install the replacement
at the same path, and restart `cloudflared-kv-vpc.service`.

## 14. Configure Syncthing

The NixOS configuration runs Syncthing as `kvineet` with:

```text
Data directory:   /home/kvineet
Configuration:    /home/kvineet/.config/syncthing
GUI:              127.0.0.1:8384
Transfer ports:   TCP/UDP 22000
Discovery port:   UDP 21027
```

The GUI listens only on loopback and is not directly exposed by the NixOS
firewall or Azure NSG. Devices and folders added through the GUI persist across
NixOS rebuilds.

### 14.1 Add the Syncthing hostname to Cloudflare Tunnel

Edit the existing `kv-vpc` tunnel in the Cloudflare Zero Trust dashboard and
add another public hostname:

```text
Subdomain: syncthing-kv-vpc
Domain:    kvineet.in
Type:      HTTP
URL:       127.0.0.1:8384
```

Under the public hostname's additional HTTP settings, set:

```text
HTTP Host Header: localhost:8384
```

Syncthing validates the HTTP Host header for its GUI. Overriding it at the
tunnel keeps Syncthing's host validation enabled instead of weakening the
service with `insecureSkipHostcheck`.

The resulting URL is:

```text
https://syncthing-kv-vpc.kvineet.in
```

No additional inbound Azure NSG rule is needed for the GUI because
`cloudflared` connects outbound to Cloudflare.

### 14.2 Protect the GUI with Cloudflare Access

Create a second Self-hosted Access application:

1. Set the hostname to `syncthing-kv-vpc.kvineet.in`.
2. Add an Allow policy restricted to the required identity or group.
3. Do not add a bypass policy.
4. Select an appropriate Access session duration.

Open the GUI after the tunnel is healthy:

```text
https://syncthing-kv-vpc.kvineet.in
```

Cloudflare Access should require authentication before forwarding the request
to Syncthing.

### 14.3 Verify Syncthing

Check the service locally:

```bash
ssh "kvineet@$VM_IP" \
  'systemctl --no-pager --full status syncthing.service'

ssh "kvineet@$VM_IP" \
  'curl --fail --silent --show-error --head http://127.0.0.1:8384'
```

Show the `kv-vpc` Syncthing device ID:

```bash
ssh "kvineet@$VM_IP" \
  'syncthing cli show system | nix shell nixpkgs#jq -c jq -r .myID'
```

Alternatively, copy the device ID from **Actions > Show ID** in the GUI.

Add remote devices and folders through the GUI. Because
`overrideDevices = false` and `overrideFolders = false`, those changes remain
in Syncthing's state after rebuilds.

### 14.4 Syncthing network connectivity

The NixOS firewall permits Syncthing's standard transfer and discovery ports.
The Azure NSG still blocks unsolicited Internet traffic unless explicit NSG
rules are added.

Syncthing can normally establish connections using global discovery, NAT
traversal, and public relays without another inbound NSG rule. If direct
connections are required, add tightly scoped Azure NSG rules for TCP and UDP
22000. Do not expose port 8384; the GUI must remain behind Cloudflare Access.

Inspect connectivity from the GUI under **Remote Devices** or from the service
log:

```bash
ssh "kvineet@$VM_IP" \
  'journalctl -u syncthing.service -n 100 --no-pager'
```

## 15. Mount Tardis photos over WireGuard

The NixOS configuration mounts Tardis's NFSv4 photos export read-write at:

```text
/mnt/photos
```

It uses the WireGuard address and NFSv4 pseudo-root path:

```text
10.100.0.1:/photos
```

The mount is a systemd automount. It does not block boot when Tardis or the
WireGuard tunnel is unavailable, and it disconnects after ten minutes of
inactivity.

Deploy and enroll WireGuard before accessing the mount. Trigger it by listing
the directory:

```bash
ssh "kvineet@$VM_IP" 'ls -la /mnt/photos'
```

Verify the resulting NFS mount:

```bash
ssh "kvineet@$VM_IP" \
  'findmnt --target /mnt/photos --output SOURCE,TARGET,FSTYPE,OPTIONS'
```

Test write access without leaving a file behind:

```bash
ssh "kvineet@$VM_IP" \
  'set -e; file=/mnt/photos/.kv-vpc-write-test-$$; touch "$file"; rm "$file"'
```

The export uses `root_squash`; perform normal file operations as `kvineet`
rather than relying on remote root privileges. NFS `sec=sys` uses numeric user
and group IDs. The NixOS configurations pin `kvineet` to UID 1000 on both
Tardis and `kv-vpc`.

Tardis declaratively manages the export root as:

```text
owner: kvineet
group: users
mode:  2775
```

The setgid bit makes new files and directories inherit the `users` group.
This rule manages the export root itself and does not recursively change
ownership or permissions of existing photos.

Troubleshoot the automount and mount units with:

```bash
ssh "kvineet@$VM_IP" \
  'systemctl --no-pager --full status mnt-photos.automount mnt-photos.mount'

ssh "kvineet@$VM_IP" \
  'journalctl -b -u mnt-photos.automount -u mnt-photos.mount --no-pager'
```

## 16. Configure Immich behind Traefik

Immich runs on `kv-vpc` with:

```text
Application:       127.0.0.1:2283
Public URL:        https://immich.kvineet.in
Media location:    /mnt/photos/immich
Database:          Local PostgreSQL managed by NixOS
Cache:             Local Redis managed by NixOS
Machine learning:  Enabled
```

Immich is not exposed directly. Traefik listens on TCP ports 80 and 443,
permanently redirects every HTTP request to HTTPS, and obtains a Let's Encrypt
certificate using the HTTP-01 challenge.

### 16.1 NFS media ownership

Immich is pinned to numeric UID and GID 980 on both Tardis and `kv-vpc`.
Tardis declaratively creates:

```text
/srv/photos/immich
owner: immich
group: immich
mode:  0700
```

This gives the hardened Immich system service read-write access over NFS
without granting access to unrelated service users.

The Immich server requires `/mnt/photos/immich` to be mounted before it starts.
If WireGuard, Tardis, or NFS is unavailable, Immich fails safely instead of
writing media into the underlying local mount-point directory.

Deploy the Tardis configuration before starting Immich so the server-side
directory and stable service identity exist.

### 16.2 Configure DNS

Create an `A` record in Cloudflare DNS:

```text
Name:    immich
Target:  AZURE_STATIC_PUBLIC_IP
TTL:     Auto
Proxy:   DNS only initially
```

Keep the record DNS-only until Traefik has obtained its first certificate.
Cloudflare proxying can be enabled afterward if desired, but Cloudflare Tunnel
is not used for Immich.

Verify DNS:

```bash
dig +short immich.kvineet.in
```

The result must be the Azure VM's static public IP.

### 16.3 Open Azure NSG ports

Traefik's HTTP-01 challenge and HTTPS endpoint require inbound TCP 80 and 443:

```bash
az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG" \
  --name "AllowHTTP" \
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --destination-port-ranges 80

az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG" \
  --name "AllowHTTPS" \
  --priority 130 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --destination-port-ranges 443
```

Do not add an NSG rule for port 2283.

### 16.4 Verify Immich and Traefik

After deploying both machines, verify the NFS media directory:

```bash
ssh "kvineet@$VM_IP" \
  'findmnt /mnt/photos && sudo -u immich test -w /mnt/photos/immich'
```

Check the services:

```bash
ssh "kvineet@$VM_IP" \
  'systemctl --no-pager --full status immich-server immich-machine-learning traefik'

ssh "kvineet@$VM_IP" \
  'journalctl -u immich-server -u traefik -n 100 --no-pager'
```

Test the loopback application:

```bash
ssh "kvineet@$VM_IP" \
  'curl --fail --silent --show-error --head http://127.0.0.1:2283'
```

Test the public endpoint:

```bash
curl --fail --silent --show-error --head https://immich.kvineet.in
```

Open the URL and create the initial Immich administrator:

```text
https://immich.kvineet.in
```

The PostgreSQL database remains on the Azure OS disk while media is stored on
Tardis. Back up both the Immich PostgreSQL database and the Tardis media
dataset; the media directory alone is not a complete Immich backup.

### 16.5 Verify the HTTPS redirect

Confirm that plain HTTP returns a permanent redirect to HTTPS:

```bash
curl --head http://immich.kvineet.in
```

The response should contain:

```text
HTTP/1.1 308 Permanent Redirect
Location: https://immich.kvineet.in/
```

### 16.6 Fail2ban protection

Traefik writes JSON access-log entries for HTTP 401 and 403 responses to:

```text
/var/lib/traefik/access.log
```

Fail2ban monitors that file across every Traefik route. An address producing
ten 401 or 403 responses within ten minutes is banned from ports 80 and 443
for one hour. Repeat offenders receive progressively longer bans, up to 24
hours.

The following private networks are excluded from bans:

```text
10.100.0.0/24
10.200.0.0/16
192.168.68.0/24
```

The DNS record should remain DNS-only when using this jail. If Cloudflare's
HTTP proxy is enabled later, Traefik may see Cloudflare edge addresses instead
of the actual client and Fail2ban could ban an edge address.

Verify the jails:

```bash
ssh "kvineet@$VM_IP" 'sudo fail2ban-client status'
ssh "kvineet@$VM_IP" 'sudo fail2ban-client status traefik-auth'
ssh "kvineet@$VM_IP" 'sudo fail2ban-client status sshd'
```

Inspect relevant logs:

```bash
ssh "kvineet@$VM_IP" \
  'sudo tail -n 20 /var/lib/traefik/access.log'

ssh "kvineet@$VM_IP" \
  'journalctl -u fail2ban -u traefik -n 100 --no-pager'
```

List or remove bans:

```bash
ssh "kvineet@$VM_IP" \
  'sudo fail2ban-client get traefik-auth banned'

ssh "kvineet@$VM_IP" \
  'sudo fail2ban-client set traefik-auth unbanip CLIENT_IP'
```

Broad 401/403 protection can ban legitimate clients that repeatedly use
expired sessions or denied URLs. Adjust `maxretry` or `findtime` if legitimate
traffic regularly reaches the threshold.

### 16.7 FireHOL known-bad client feed

In addition to reactive Fail2ban jails, the firewall downloads FireHOL Level 1
and blocks listed IPv4 networks from Traefik's public TCP ports 80 and 443.
SSH, WireGuard, and other services are not affected by this feed.

The updater:

- Downloads over HTTPS from the FireHOL blocklist repository.
- Rejects malformed downloads.
- Rejects downloads containing fewer than 1,000 entries.
- Builds a new `ipset` before atomically swapping it into service.
- Keeps the previous active set when an update fails.
- Refreshes hourly with a randomized delay.

The WireGuard, Azure VNet, and home LAN ranges are allowlisted ahead of the
feed:

```text
10.100.0.0/24
10.200.0.0/16
192.168.68.0/24
```

Check the timer and most recent update:

```bash
ssh "kvineet@$VM_IP" \
  'systemctl --no-pager --full status firehol-level1-update.timer'

ssh "kvineet@$VM_IP" \
  'journalctl -u firehol-level1-update.service -n 100 --no-pager'
```

Inspect the active sets:

```bash
ssh "kvineet@$VM_IP" \
  'sudo ipset list firehol_level1 | head -n 30'

ssh "kvineet@$VM_IP" \
  'sudo ipset list firehol_allow'
```

Force an update:

```bash
ssh "kvineet@$VM_IP" \
  'sudo systemctl start firehol-level1-update.service'
```

#### Unban an IP

First determine whether the address was banned by Fail2ban:

```bash
ssh "kvineet@$VM_IP" \
  'sudo fail2ban-client get traefik-auth banned'
```

Remove a reactive Fail2ban ban:

```bash
ssh "kvineet@$VM_IP" \
  'sudo fail2ban-client set traefik-auth unbanip CLIENT_IP'
```

If the address is covered by FireHOL, add it to the higher-priority allowlist:

```bash
ssh "kvineet@$VM_IP" \
  'sudo ipset add firehol_allow CLIENT_IP -exist'
```

That command takes effect immediately but is temporary. To preserve the
exception across firewall reloads and reboots, add the address or CIDR to
`fireholAllowlist` in `machines/kv-vpc/configuration.nix`, then deploy the
configuration.

Check whether an address matches either set:

```bash
ssh "kvineet@$VM_IP" \
  'sudo ipset test firehol_level1 CLIENT_IP; sudo ipset test firehol_allow CLIENT_IP'
```

Removing an address directly from `firehol_level1` is not persistent because
the next feed update will add it again. Use `firehol_allow` for exceptions.

## 17. Configure Baby Buddy

Baby Buddy runs as a Docker-backed NixOS OCI container:

```text
Image:          lscr.io/linuxserver/babybuddy:latest
Internal URL:   http://127.0.0.1:8000
Public URL:     https://babybuddy.kvineet.in
Persistent data: /var/lib/babybuddy
```

The container port is published only on loopback. Traefik is the only public
port does not expose Baby Buddy publicly. The existing `kv-vpc` Cloudflare
Tunnel publishes the loopback service. Immich remains on Traefik and is
unaffected by this setup.

The Compose environment files are replaced by declarative values:

```text
PUID=1000
PGID=100
TZ=Asia/Kolkata
CSRF_TRUSTED_ORIGINS=http://127.0.0.1:8000,https://babybuddy.kvineet.in
```

`/var/lib/babybuddy` is owned by `kvineet:users`, matching the container's
PUID 1000 and PGID 100. The Compose `proxy` network is not needed because
Cloudflare Tunnel reaches the loopback-published port directly.

### 17.1 Configure the Cloudflare Tunnel hostname

Edit the existing `kv-vpc` tunnel in the Cloudflare Zero Trust dashboard and
add a public hostname:

```text
Subdomain: babybuddy
Domain:    kvineet.in
Type:      HTTP
URL:       127.0.0.1:8000
```

The resulting URL is:

```text
https://babybuddy.kvineet.in
```

Cloudflare creates the required proxied DNS record and provides public HTTPS.
The connector initiates an outbound connection, so no Baby Buddy, HTTP, or
HTTPS Azure NSG rule is required for this route.

Verify that the existing tunnel is healthy:

```bash
ssh "kvineet@$VM_IP" \
  'systemctl --no-pager --full status cloudflared-kv-vpc.service'

ssh "kvineet@$VM_IP" \
  'journalctl -u cloudflared-kv-vpc.service -n 100 --no-pager'
```

### 17.2 Deploy and verify

After deploying `kv-vpc`, verify Docker and the container:

```bash
ssh "kvineet@$VM_IP" \
  'systemctl --no-pager --full status docker docker-babybuddy'

ssh "kvineet@$VM_IP" \
  'sudo docker ps --filter name=babybuddy'

ssh "kvineet@$VM_IP" \
  'journalctl -u docker-babybuddy -n 100 --no-pager'
```

Test the loopback service:

```bash
ssh "kvineet@$VM_IP" \
  'curl --fail --silent --show-error --head http://127.0.0.1:8000'
```

Test the public Cloudflare Tunnel endpoint:

```bash
curl --fail --silent --show-error --head \
  https://babybuddy.kvineet.in
```

Open Baby Buddy and complete its initial setup:

```text
https://babybuddy.kvineet.in
```

Back up `/var/lib/babybuddy`; it contains the application's persistent
configuration and database.

Baby Buddy traffic does not pass through Traefik, so the Traefik 401/403
Fail2ban jail does not apply to this hostname. Use Cloudflare Access or
Cloudflare WAF/rate-limiting policies if additional edge protection is
required.

### 17.3 Automatic image updates

A persistent systemd timer checks the LinuxServer `latest` tag daily with up
to two hours of randomized delay:

```text
babybuddy-image-update.timer
```

The updater pulls the image and compares its image ID with the previously
installed image. It restarts `docker-babybuddy.service` only when the image ID
changed. A failed pull leaves the currently running container untouched.

Check the schedule:

```bash
ssh "kvineet@$VM_IP" \
  'systemctl list-timers babybuddy-image-update.timer'
```

Run an update check immediately:

```bash
ssh "kvineet@$VM_IP" \
  'sudo systemctl start babybuddy-image-update.service'
```

Inspect update results:

```bash
ssh "kvineet@$VM_IP" \
  'journalctl -u babybuddy-image-update.service -n 100 --no-pager'
```

The container may be briefly unavailable only when an updated image is
detected and the service is recreated. Watchtower is intentionally not used,
avoiding a third-party container with root-equivalent access to the Docker
socket.

## 18. Configure Telegram service-failure alerts

Selected application and infrastructure services trigger a Telegram
notification when systemd marks them failed. Alerts include:

- Hostname
- Failed unit
- systemd result
- Active and sub-state
- Main process exit status
- Timestamp

Journal contents are not included because they may contain sensitive data.

The monitored units include Baby Buddy and its updater, Docker, Immich and its
database/cache dependencies, Syncthing, Traefik, Cloudflared, Fail2ban,
FireHOL updates, WireGuard setup, the firewall, Azure Agent, and cloud-init.

### 18.1 Create the Telegram destination

Create a bot with Telegram's `@BotFather`, add it to the target chat if
necessary, and obtain the chat ID.

The Shoutrrr URL has this format:

```text
telegram://BOT_TOKEN@telegram?chats=CHAT_ID
```

Shoutrrr can interactively generate the URL:

```bash
nix shell nixpkgs#shoutrrr -c shoutrrr generate telegram
```

### 18.2 Install the Shoutrrr URL

Read the URL without adding it to shell history:

```bash
read -rsp 'Shoutrrr Telegram URL: ' SHOUTRRR_TELEGRAM_URL
printf '\n'
```

Install it as a root-owned runtime secret:

```bash
printf '%s' "$SHOUTRRR_TELEGRAM_URL" |
  ssh "kvineet@$VM_IP" \
    'sudo install -D -m 0600 /dev/stdin /var/lib/shoutrrr/telegram-url'

unset SHOUTRRR_TELEGRAM_URL
```

The URL is loaded into the notification unit with systemd credentials and
does not enter the Nix store. Until the file exists, failure notifications are
skipped without affecting the monitored service.

### 18.3 Test notifications

Send a test notification without failing an application:

```bash
ssh "kvineet@$VM_IP" \
  'sudo systemctl start telegram-notify@traefik.service'
```

Inspect notifier failures:

```bash
ssh "kvineet@$VM_IP" \
  'journalctl -u "telegram-notify@*" -n 100 --no-pager'
```

If the Telegram bot token or chat changes, replace
`/var/lib/shoutrrr/telegram-url`; no NixOS rebuild is required.

## 19. Subsequent deployments

After committing or otherwise tracking the new host files, rebuild remotely:

```bash
nixos-rebuild switch \
  --flake .#kv-vpc \
  --target-host "kvineet@$VM_IP" \
  --sudo
```

If `nixos-rebuild` is not installed locally:

```bash
nix shell nixpkgs#nixos-rebuild -c \
  nixos-rebuild switch \
    --flake .#kv-vpc \
    --target-host "kvineet@$VM_IP" \
    --sudo
```

## 20. Optional cleanup

Deleting the resource group permanently deletes the VM, disks, public IP,
VNet, NSG, and associated resources:

```bash
az group delete \
  --name "$RESOURCE_GROUP" \
  --yes \
  --no-wait
```

Run this only when the entire deployment is no longer needed.
