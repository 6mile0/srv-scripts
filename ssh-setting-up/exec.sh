# This script is for setting up ssh connection with github

# github username
USER=6mile0

# choose ssh port number
PORTNUM=$(shuf -i 25555-55555 -n 1)

# when root userrun this script, create new user
if [ $(id -u) -eq 0 ]; then
    read -p "Enter new user name: " NEWUSER
    adduser $NEWUSER
    usermod -aG sudo $NEWUSER
    su - $NEWUSER
fi

# when not install curl, install curl
if ! [ -x "$(command -v curl)" ]; then
    sudo apt-get update
    sudo apt-get install -y curl
fi

# when not install openssh-server, install openssh-server
if ! [ -x "$(command -v ssh)" ]; then
    sudo apt-get update
    sudo apt-get install -y openssh-server
fi

## SSH setting

ACCESSUSER=$(whoami)

# check sshd_config.d directory
if [ ! -d /etc/ssh/sshd_config.d ]; then
    sudo mkdir /etc/ssh/sshd_config.d
    sudo chmod 755 /etc/ssh/sshd_config.d
fi

# when exsist 00-custom.conf, remove it
if [ -f /etc/ssh/sshd_config.d/00-custom.conf ]; then
    sudo rm /etc/ssh/sshd_config.d/00-custom.conf
fi

# make custom setting file
# Thanks to https://zenn.dev/y_mrok/articles/ssh_security_measures
cat <<EOF | sudo tee -a /etc/ssh/sshd_config.d/00-custom.conf
# This is custom setting for sshd_config made by 6mile

# change ssh port number
Port $PORTNUM

# protocol 2 only
Protocol 2

# change PermitRootLogin to no
PermitRootLogin no

# change PasswordAuthentication to no
PasswordAuthentication no

# change PubkeyAuthentication to yes
PubkeyAuthentication yes

# change challenge response to no
ChallengeResponseAuthentication no

# change keyboard-interactive to no
KbdInteractiveAuthentication no

# change GSSAPI authentication to no
GSSAPIAuthentication no

# change kerberos authentication to no
KerberosAuthentication no

# restrict user login
AllowUsers $ACCESSUSER

# change max login attempts
MaxAuthTries 2

# change MaxStartups
MaxStartups 10:30:100

# config logging
SyslogFacility AUTHPRIV

# config log level
LogLevel VERBOSE

EOF

# restart ssh service
sudo service ssh restart


## SSH User setting

# when not exsist, making ~/.ssh directory
mkdir -p ~/.ssh/

# download public key from github
curl -s https://github.com/$USER.keys > ~/.ssh/authorized_keys

# change permission of ~/.ssh directory
chmod 700 ~/.ssh/

# change permission of ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo 'Congratulation! You can try to connect the server with the following command'
echo "LAN >>> ssh -p $PORTNUM $USER@$(hostname -I)"
echo "WAN >>> ssh -p $PORTNUM $USER@$(curl -s ipinfo.io/ip)"
