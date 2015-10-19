#! /bin/bash
## Description: Creates a TeleStax support account
## Parameters : none
## Authors    : Henrique Rosa   henrique.rosa@telestax.com   

USERNAME='telestax'
SUDOERS=/etc/sudoers.d
SSH_CONFIG=/etc/ssh/sshd_config

# Create a user account if user does not exist
grep -q -e "^$USERNAME:" /etc/passwd || useradd -c 'TeleStax Support' $USERNAME
echo "Created user $USERNAME"

# Give admin privileges to telestax user
echo 'Defaults env_keep += "JAVA_HOME"' > $SUDOERS/$USERNAME
echo "$USERNAME ALL=(root) NOPASSWD:ALL" >> $SUDOERS/$USERNAME
echo "Given Admin privileges to $USERNAME user"

# Configure ssh key for telestax user
mkdir -p /home/$USERNAME/.ssh
chmod 700 $MOUNTPOINT/home/$USERNAME/.ssh
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh

# TeleStax user must authenticate with the provided private key
cat > /home/$USERNAME/.ssh/authorized_keys << EOF2
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2c30clPmfHbFNJeRWpRU3ITucACu5ZcvLpx5vbsPd3VaAYheIpS4eJWH0L9+DBXv225m0M9jn1ua2QhfSjJOosq7f9gXXsHlF5gqATs5UpnkDopRCe/r1na0zg/82jxfgFtHS12kuC8t+6ENNmeQOoXdpi3lxBVblkHrFMQ5Dvd4xlHvxYONVZbhNTck+rbk2AhzkfYgWNRlWKph7EIi2cPwvMiliX8QZEBYPYchjL/fa7Sc/GxX8cvYTunhs3CqT2+x9+R14lLI68uBy/QozuBdLP/fIERkWHzDb8GRlbN8Wa8dpZYZwcDwzcfkid2p4D1MlsoC3mRQa/mS70stX support
EOF2
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/authorized_keys
echo "Registered private key for SSH access"

grep -q -e "AllowUsers .*$USERNAME" $SSH_CONFIG || sed -e "/AllowUsers/ s|$| $USERNAME|" $SSH_CONFIG > $SSH_CONFIG.bak
[ -f $SSH_CONFIG.bak ] && mv $SSH_CONFIG.bak $SSH_CONFIG
echo "Allowed SSH access to $USERNAME user"

# Reload SSH configuration
/etc/init.d/sshd reload
echo "$USERNAME successfully configured!"