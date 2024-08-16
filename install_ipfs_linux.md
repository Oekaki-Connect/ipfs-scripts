# IPFS Installation Guide for Linux

This guide will walk you through the process of installing IPFS (InterPlanetary File System) on a fresh Linux VPS, including setting up the Uncomplicated Firewall (UFW).

## Prerequisites

- A Linux VPS (e.g., Ubuntu, Debian)
- SSH access to your VPS
- Root or sudo privileges

## Step 1: Connect to Your VPS

Use SSH to connect to your VPS:

```
ssh username@your_ip_address
```

Replace `username` and `your_ip_address` with your actual username and VPS IP address.

## Step 2: Update Your System

Update your package lists and upgrade existing packages:

```
sudo apt update && sudo apt upgrade -y
```

## Step 3: Install UFW

Install the Uncomplicated Firewall (UFW):

```
sudo apt install ufw -y
```

## Step 4: Configure UFW

Set up basic firewall rules:

```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 4001/tcp
sudo ufw allow 4001/udp
sudo ufw allow 8080/tcp
```

Enable the firewall:

```
sudo ufw enable
```

Check the status:

```
sudo ufw status
```

## Step 5: Install IPFS

1. Download IPFS:
   Visit https://dist.ipfs.tech/#go-ipfs to check the latest version number. Replace `<version>` in the following commands with the current version:
   
   ex: https://dist.ipfs.tech/kubo/v0.29.0/kubo_v0.29.0_linux-amd64.tar.gz

   ```
   wget https://dist.ipfs.tech/go-ipfs/<version>/go-ipfs_<version>_linux-amd64.tar.gz
   tar -xvzf go-ipfs_<version>_linux-amd64.tar.gz
   ```

2. Install IPFS:
   ```
   cd go-ipfs
   sudo bash install.sh
   ```

3. Initialize IPFS:
   ```
   ipfs init
   ```

## Step 6: Configure IPFS as a Service

1. Create a systemd service file:
   ```
   sudo nano /etc/systemd/system/ipfs.service
   ```

2. Add the following content to the file:
   ```
   [Unit]
   Description=IPFS Daemon
   After=network.target

   [Service]
   ExecStart=/usr/local/bin/ipfs daemon
   User=root
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

3. Save and exit the editor (Ctrl+X, then Y, then Enter).

4. Enable and start the IPFS service:
   ```
   sudo systemctl daemon-reload
   sudo systemctl enable ipfs
   sudo systemctl start ipfs
   ```

## Step 7: Verify Installation

Check IPFS version and ID:

```
ipfs version
ipfs id
```

## Conclusion

You have now successfully installed IPFS on your Linux VPS and configured UFW to allow the necessary connections. IPFS is running as a system service and will start automatically on boot.

For more information on using IPFS, please refer to the official IPFS documentation: https://docs.ipfs.tech/