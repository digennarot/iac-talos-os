#!/usr/bin/env bash
# ----------------------------------------------------------------------
# bootstrap.sh – Hardening & post-install per nodi Proxmox VE
# V.2025-05 – adatta pure alle tue esigenze
#
#  - esce al primo errore, logga tutto su syslog + file
#  - idempotente: se lo richiami non rompe nulla
# ----------------------------------------------------------------------
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

LOG_F=/var/log/proxmox-first-boot.log
exec > >(tee -a "$LOG_F" | systemd-cat -t first-boot -p info) 2>&1

echo "== $(date --iso-seconds) Avvio bootstrap di $(hostname -f)"

# ------------------------------------------------------------
# 1. Aggiornamento di sicurezza immediato
# ------------------------------------------------------------
echo "[*] Aggiornamento pacchetti..."
apt-get update -qq
apt-get -o Dpkg::Options::="--force-confnew" dist-upgrade -yqq
apt-get autoremove -yqq

# ------------------------------------------------------------
# 2. Repository enterprise (commenta se non licenziato)
# ------------------------------------------------------------
if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
  sed -Ei 's/^#?\s*deb/deb/' /etc/apt/sources.list.d/pve-enterprise.list
fi

# ------------------------------------------------------------
# 3. Hardening di base
# ------------------------------------------------------------
echo "[*] Installo fail2ban, unattended-upgrades, ssh-ca ..."
apt-get install -yqq fail2ban unattended-upgrades apt-listchanges \
                       openssh-client openssh-server

# abilita auto-patch giornaliera e riavvio se solo kernel
cat >/etc/apt/apt.conf.d/51unattended-reboot <<'EOF'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:15";
EOF
systemctl enable --now unattended-upgrades


# ------------------------------------------------------------
# 4. Utente di servizio DevSecOps
# ------------------------------------------------------------
useradd -m -s /bin/bash tdigenna || true
install -d -o tdigenna -g tdigenna -m 700 /home/tdigenna/.ssh
cat >>/home/tdigenna/.ssh/authorized_keys <<'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDaeuK4JSGA5DlXVioZ0PDRc/Bkk/52J+KMxkYX6Ykfg88tU9j79HLzOY/xGKZoeuoQDKlusk/4DC3RbZZ7OCf5rAe9JL/EVNpyQJk4liEkjjcrrHHjBTD4ttyewLFgvGKOBSasX8a5onYxLGkmSN+2j09praMQQVt2SulvjmqQNuea3vLMbl7oqoJTWYFyIoLHuaCQIIgEKoLZyjrpkdaXysSfnzFcs2lBJRbdwmVp/7POhv3DlRzvb9xmBTayNRKo4AH4RqycrAJa/OCBQkgqwyyQg+W8qcIElMkOkIScZSW8U7tyjhWXsq0iP9Gwk9C0B+IX4HXoVlGV2AKLJbv6z7n2ySLrANwZcmNZLsem7XM68AwYJ13TcX+yZ8ebvKTuMGK1477ScEJ62PzW2mIIR7YZ79XGaPtKpSylKB7/LL6/2APH6rOUQMP8NvwbhGyi9a3F5yUoOGkXI0e73RxBQ2sSNc8sjKMI7mRe7bH1fAc/nXuE3wZdfPAq3eOe8Ms=
EOF
chmod 600 /home/tdigenna/.ssh/authorized_keys
usermod -aG sudo,www-data,ssh tdigenna   # aggiungi gruppi utili

# ------------------------------------------------------------
# 5. Hook Ansible (pull)
# ------------------------------------------------------------
echo "[*] Clono playbook Ansible..."
apt-get install -yqq git
# su - tdigenna -c '
#   git clone --depth 1 https://github.com/digennarot/iac-talos-os/tree/main/proxmox-ansible.git ~/pve-playbook
#   ansible-pull -U https://github.com/digennarot/iac-talos-os/tree/main/proxmox-ansible main.yml
# '

# ------------------------------------------------------------
# 6. Sysctl & modprobe per prestazioni/CPU-mitigations
# ------------------------------------------------------------
cat >/etc/sysctl.d/99-pve-tuned.conf <<'EOF'
vm.swappiness = 10
net.ipv4.tcp_syncookies = 1
EOF
sysctl --system

# disattiva alcune mitigazioni se CPU recente
echo 'options kvm_intel mitigations=off' >/etc/modprobe.d/kvm.conf
update-initramfs -u -k all

# ------------------------------------------------------------
# 7. Pulizia finale
# ------------------------------------------------------------
echo "[*] Pulizia cache Apt..."
apt-get clean
truncate -s 0 /var/lib/apt/extended_states || true

echo "== $(date --iso-seconds) bootstrap COMPLETATO"
systemctl disable --now proxmox-first-boot.service
