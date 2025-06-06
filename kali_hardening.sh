#!/bin/bash
# Kali Linux Hardening Script v1.0
# Author: SmaRTy Saini (https://github.com/smarty-saini)
# License: MIT
# DISCLAIMER: For educational and defensive use only. See full disclaimer below.

echo "[+] Starting Kali Linux System Hardening..."

# System update
sudo apt update && sudo apt upgrade -y

# Security tools
sudo apt install -y fail2ban libpam-tmpdir apt-listbugs apt-listchanges libpam-pwquality auditd acct unattended-upgrades debsums apt-show-versions tripwire

# PAM password strength
echo "password requisite pam_pwquality.so retry=3 minlen=14 dcredit=-1 ucredit=-1 ocredit=-1" | sudo tee /etc/pam.d/common-password

# Kernel hardening
cat <<EOF | sudo tee /etc/sysctl.d/99-kali-hardening.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.ctrl-alt-del=0
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.log_martians=1
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
EOF
sudo sysctl --system

# USB/firewire lockdown
echo "install usb-storage /bin/true" | sudo tee /etc/modprobe.d/disable-usb.conf
echo "install firewire-ohci /bin/true" | sudo tee /etc/modprobe.d/disable-firewire.conf

# Legal login banner
echo "Authorized access only. All activity may be monitored and reported." | sudo tee /etc/issue /etc/issue.net

# SSH hardening
if command -v sshd >/dev/null 2>&1; then
  sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo systemctl restart ssh
fi

# iptables firewall
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Ensure netfilter-persistent is available
sudo apt install -y netfilter-persistent
sudo netfilter-persistent save
sudo systemctl enable netfilter-persistent

# Enable unattended upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Flag reboot
touch /tmp/REBOOT_NEEDED
echo "[+] Hardening complete. Reboot recommended."
