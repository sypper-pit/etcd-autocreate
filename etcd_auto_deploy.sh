#!/bin/bash

set -e

# --- 0. Configurable variables ---
ETCD_VER="v3.6.0"
CLUSTER_TOKEN="etcd-cluster"

echo "==== ETCD Automated Installer (with /etc/etcd/etcd.conf.yml) ===="

# --- 1. User Input ---
read -p "Enter the name of this node (e.g., etcd-db0): " NODE_NAME
read -p "Enter the IP or hostname of this node: " NODE_HOST
read -p "Enter ALL cluster node hostnames or IPs, comma-separated (e.g., etcd-db0,etcd-db1,etcd-db2): " NODES_LIST
read -p "Enter initial-cluster-state (new or existing): " CLUSTER_STATE

# --- 2. Build initial-cluster string ---
IFS=',' read -ra HOSTS <<< "$NODES_LIST"
INITIAL_CLUSTER=""
for host in "${HOSTS[@]}"; do
    if [ -n "$INITIAL_CLUSTER" ]; then
        INITIAL_CLUSTER+=","
    fi
    INITIAL_CLUSTER+="${host}=http://${host}:2380"
done

# --- 3. Download and Install etcd ---
GOOGLE_URL=https://storage.googleapis.com/etcd
DOWNLOAD_URL=${GOOGLE_URL}

echo "Downloading etcd $ETCD_VER..."
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1 --no-same-owner
sudo cp /tmp/etcd-download-test/etcd /usr/local/bin/
sudo cp /tmp/etcd-download-test/etcdctl /usr/local/bin/
sudo cp /tmp/etcd-download-test/etcdutl /usr/local/bin/

# --- 4. Create User and Directories ---
sudo groupadd --system etcd 2>/dev/null || true
sudo useradd -s /sbin/nologin --system -g etcd etcd 2>/dev/null || true
sudo mkdir -p /var/lib/etcd
sudo mkdir -p /etc/etcd
sudo chown -R etcd:etcd /var/lib/etcd
sudo chmod -R 700 /var/lib/etcd

# --- 5. Open Firewall Ports ---
sudo ufw allow 2380/tcp
sudo ufw allow 2379/tcp

# --- 6. Generate /etc/etcd/etcd.conf.yml ---
sudo tee /etc/etcd/etcd.conf.yml > /dev/null <<EOF
name: ${NODE_NAME}
data-dir: /var/lib/etcd
initial-advertise-peer-urls: http://${NODE_HOST}:2380
listen-peer-urls: http://0.0.0.0:2380
listen-client-urls: http://0.0.0.0:2379
advertise-client-urls: http://${NODE_HOST}:2379
initial-cluster: ${INITIAL_CLUSTER}
initial-cluster-state: ${CLUSTER_STATE}
initial-cluster-token: ${CLUSTER_TOKEN}
EOF

sudo chown etcd:etcd /etc/etcd/etcd.conf.yml
sudo chmod 600 /etc/etcd/etcd.conf.yml

# --- 7. Create systemd unit file ---
sudo tee /etc/systemd/system/etcd.service > /dev/null <<EOF
[Unit]
Description=etcd
After=network.target

[Service]
User=etcd
Group=etcd
Type=notify
ExecStart=/usr/local/bin/etcd --config-file=/etc/etcd/etcd.conf.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# --- 8. Start etcd ---
sudo systemctl daemon-reload
sudo systemctl enable --now etcd

echo
echo "etcd has been installed and started successfully!"
echo "Check etcd status:"
echo "  sudo systemctl status etcd"
echo

# --- 9. Output cluster status command ---
ENDPOINTS=""
for host in "${HOSTS[@]}"; do
    if [ -n "$ENDPOINTS" ]; then
        ENDPOINTS+=","
    fi
    ENDPOINTS+="${host}:2379"
done

echo "To check cluster status, run:"
echo "  ETCDCTL_API=3 etcdctl --endpoints=${ENDPOINTS} endpoint status --cluster -w table"
echo

