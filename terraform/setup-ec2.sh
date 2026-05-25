#!/bin/bash
# ============================================================
# CropGuard AI — EC2 Setup Script
# Installs: Docker, Jenkins, K3s, AWS CLI
# Run as: sudo ./setup-ec2.sh
# ============================================================

set -euo pipefail

echo "=========================================="
echo "  CropGuard AI — EC2 Setup Starting"
echo "=========================================="

# ============================================================
# 1. SYSTEM UPDATE
# ============================================================
echo "[1/5] Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  unzip \
  jq \
  software-properties-common

# ============================================================
# 2. INSTALL DOCKER
# ============================================================
echo "[2/5] Installing Docker..."

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Allow ubuntu user to use Docker
usermod -aG docker ubuntu

systemctl enable docker
systemctl start docker

echo "  ✅ Docker installed: $(docker --version)"

# ============================================================
# 3. INSTALL JENKINS
# ============================================================
echo "[3/5] Installing Jenkins..."

# Install Java 17 (Jenkins dependency)
apt-get install -y fontconfig openjdk-17-jre

# Add Jenkins repo
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
  tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | \
  tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

# Add jenkins user to docker group so Jenkins can build images
usermod -aG docker jenkins

systemctl enable jenkins
systemctl start jenkins

echo "  ✅ Jenkins installed and running on port 8080"

# ============================================================
# 4. INSTALL K3s (Lightweight Kubernetes)
# ============================================================
echo "[4/5] Installing K3s..."

curl -sfL https://get.k3s.io | sh -

# Wait for K3s to be ready
sleep 10
until k3s kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  echo "  Waiting for K3s to be ready..."
  sleep 5
done

# Configure kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 600 /home/ubuntu/.kube/config

# Configure kubectl for jenkins user
mkdir -p /var/lib/jenkins/.kube
cp /etc/rancher/k3s/k3s.yaml /var/lib/jenkins/.kube/config
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chmod 600 /var/lib/jenkins/.kube/config

# Add KUBECONFIG to jenkins environment
echo "KUBECONFIG=/var/lib/jenkins/.kube/config" >> /etc/default/jenkins

echo "  ✅ K3s installed: $(k3s kubectl version --short 2>/dev/null || echo 'ready')"

# ============================================================
# 5. INSTALL AWS CLI v2
# ============================================================
echo "[5/5] Installing AWS CLI v2..."

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp/
/tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "  ✅ AWS CLI installed: $(aws --version)"

# ============================================================
# 6. ECR CREDENTIAL HELPER — Auto-refresh for K3s image pulls
# ============================================================
echo "[BONUS] Setting up ECR credential refresh..."

# Get AWS region and account ID from instance metadata
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
AWS_ACCOUNT_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.accountId')

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Create the ECR login refresh script
cat > /usr/local/bin/ecr-login-refresh.sh << 'EOFSCRIPT'
#!/bin/bash
# Refresh ECR credentials for K3s to pull images
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AWS_REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
AWS_ACCOUNT_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.accountId')
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Get ECR password and create K3s registry config
ECR_PASSWORD=$(aws ecr get-login-password --region "$AWS_REGION")

mkdir -p /etc/rancher/k3s
cat > /etc/rancher/k3s/registries.yaml << EOF
mirrors:
  "${ECR_REGISTRY}":
    endpoint:
      - "https://${ECR_REGISTRY}"
configs:
  "${ECR_REGISTRY}":
    auth:
      username: AWS
      password: "${ECR_PASSWORD}"
EOF

# Restart K3s to pick up new credentials
systemctl restart k3s
EOFSCRIPT

chmod +x /usr/local/bin/ecr-login-refresh.sh

# Run it now to set up initial credentials
/usr/local/bin/ecr-login-refresh.sh

# Set up cron to refresh every 6 hours (ECR tokens expire in 12 hours)
echo "0 */6 * * * root /usr/local/bin/ecr-login-refresh.sh" > /etc/cron.d/ecr-login-refresh

echo "  ✅ ECR credential auto-refresh configured"

# ============================================================
# RESTART JENKINS to pick up docker group and kubeconfig
# ============================================================
systemctl restart jenkins

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "=========================================="
echo "  ✅ CropGuard AI — EC2 Setup Complete!"
echo "=========================================="
echo ""
echo "  Docker:  $(docker --version)"
echo "  Jenkins: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "  K3s:     $(k3s --version)"
echo "  AWS CLI: $(aws --version)"
echo ""
echo "  Jenkins initial password:"
echo "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "  K3s nodes:"
echo "  $(k3s kubectl get nodes 2>/dev/null || echo 'starting...')"
echo ""
echo "=========================================="
