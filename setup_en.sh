#!/bin/bash
printf "\033c"

error=""
node="v14.19.1"
arch=$(uname -m)
mcsmanager_install_path="/opt/mcsmanager"

Red_Error() {
  echo '================================================='
  printf '\033[1;31;40m%b\033[0m\n' "$@"
  echo '================================================='
  exit 1
}

echo_red() {
  printf '\033[1;31m%b\033[0m\n' "$@"
}

echo_green() {
  printf '\033[1;32m%b\033[0m\n' "$@"
}

echo_cyan() {
  printf '\033[1;36m%b\033[0m\n' "$@"
}

echo_cyan_n() {
  printf '\033[1;36m%b\033[0m' "$@"
}

echo_yellow() {
  printf '\033[1;33m%b\033[0m\n' "$@"
}

Install_Node() {
  echo_cyan_n "[+] Install Node environment... "

  rm -irf "$node_install_path"

  cd /opt || exit

  wget -o /dev/null https://nodejs.org/dist/"$node"/node-"$node"-linux-"$arch".tar.gz

  tar -zxf node-"$node"-linux-"$arch".tar.gz

  rm -rf node-"$node"-linux-"$arch".tar.gz

  if [ -f "$node_install_path"/bin/node ] && [ "$("$node_install_path"/bin/node -v)" == "$node" ]
  then
    echo_green "Success"
  else
    echo_red "Failed"
    Red_Error "[x] Node installation failed!"
  fi

  echo
  echo_yellow "=============== Node Version ==============="
  echo_yellow " node: $("$node_install_path"/bin/node -v)"
  echo_yellow " npm: v$(/usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm -v)"
  echo_yellow "=============== Node Version ==============="
  echo

  sleep 3
}

Install_MCSManager() {
  echo_cyan "[+] Install MCSManager..."

  # delete service
  rm -f /etc/systemd/system/mcsm-daemon.service
  rm -f /etc/systemd/system/mcsm-web.service

  # reload
  systemctl daemon-reload
  
  # echo "[x] Delete the original MCSManager"
  rm -irf ${mcsmanager_install_path}

  # echo "[+] mkdir -p ${mcsmanager_install_path}"
  mkdir -p ${mcsmanager_install_path} || exit

  # echo "[→] cd ${mcsmanager_install_path}"
  cd ${mcsmanager_install_path} || exit

  echo_cyan "[↓] Git clone MCSManager-Daemon..."
  git clone --single-branch -b master --depth 1 https://github.com/MCSManager/MCSManager-Daemon-Production.git

  # echo "[-] mv MCSManager-Daemon-Production daemon"
  mv MCSManager-Daemon-Production daemon

  # echo "[→] cd daemon"
  cd daemon || exit

  echo_cyan "[+] Install MCSManager-Daemon dependencies..."
  /usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm install --registry=https://registry.npmmirror.com > error

  # echo "[←] cd .."
  cd ..

  echo_cyan "[↓] Git clone MCSManager-Web..."
  git clone --single-branch -b master --depth 1 https://github.com/MCSManager/MCSManager-Web-Production.git

  # echo "[-] mv MCSManager-Web-Production web"
  mv MCSManager-Web-Production web

  # echo "[→] cd web"
  cd web || exit

  echo_cyan "[+] Install MCSManager-Web dependencies..."
  /usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm install --registry=https://registry.npmmirror.com > error

  echo
  echo_yellow "=============== MCSManager ==============="
  echo_green " Daemon: ${mcsmanager_install_path}/daemon"
  echo_green " Web: ${mcsmanager_install_path}/web"
  echo_yellow "=============== MCSManager ==============="
  echo
  echo_green "[+] MCSManager installation success!"

  sleep 3
}

Create_Service() {
  echo_cyan "[+] Create MCSManager service..."

  echo "
[Unit]
Description=MCSManager Daemon

[Service]
WorkingDirectory=/opt/mcsmanager/daemon
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/mcsm-daemon.service

  echo "
[Unit]
Description=MCSManager Web

[Service]
WorkingDirectory=/opt/mcsmanager/web
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/mcsm-web.service

  systemctl daemon-reload
  systemctl enable mcsm-daemon.service --now
  systemctl enable mcsm-web.service --now

  sleep 3

  printf "\033c"
  echo_yellow "=================================================================="
  echo_green "Welcome to MCSManager, you can access it by the following ways:"
    echo_yellow "=================================================================="
    echo_cyan_n "Daemon Service Address: "; echo_yellow "http://localhost:24444"
    echo_cyan_n "Web Service Address:    "; echo_yellow "http://localhost:23333"
    echo_cyan_n "Username: "; echo_yellow "root"
    echo_cyan_n "Password: "; echo_yellow "123456"
    echo_red "You must expose ports 23333 and 24444 to use the service properly on the Internet."
    echo_yellow "=================================================================="
    echo_cyan "systemctl restart mcsm-{daemon,web}.service"
    echo_cyan "systemctl disable mcsm-{daemon,web}.service"
    echo_cyan "systemctl enable mcsm-{daemon,web}.service"
    echo_cyan "systemctl start mcsm-{daemon,web}.service"
    echo_cyan "systemctl stop mcsm-{daemon,web}.service"
    echo_cyan "More info: https://docs.mcsmanager.com/"
  echo_yellow "=================================================================="


}


# ----------------- Program Start -----------------

# delete the shell script itself
rm -f "$0"

# Check execute user permissions
if [ "$(whoami)" != "root" ]; then
  Red_Error "[x] Please execute the MCSManager installation command with root permission!"
fi

echo_cyan "+----------------------------------------------------------------------
| MCSManager Installer
+----------------------------------------------------------------------
| Copyright © 2022 MCSManager All rights reserved.
+----------------------------------------------------------------------
| Shell Install Script by Nuomiaa & CreeperKong
+----------------------------------------------------------------------
"

# Environmental inspection
if [ "$arch" == x86_64 ]; then
  arch=x64
  #echo "[-] x64 architecture detected"
elif [ $arch == aarch64 ]; then
  arch=arm64
  #echo "[-] 64-bit ARM architecture detected"
elif [ $arch == arm ]; then
  arch=armv7l
  #echo "[-] 32-bit ARM architecture detected"
elif [ $arch == ppc64le ]; then
  arch=ppc64le
  #echo "[-] IBM POWER architecture detected"
elif [ $arch == s390x ]; then
  arch=s390x
  #echo "[-] IBM LinuxONE architecture detected"
else
  Red_Error "[x] Sorry, this architecture is not supported yet!"
  exit
fi

# Define the variable Node installation directory
node_install_path="/opt/node-$node-linux-$arch"

# Check network connection
echo_cyan "[-] Architecture: $arch"

# MCSManager Installed
if [ -d "$mcsmanager_install_path" ]; then
  printf "\033c"
  echo_red "----------------------------------------------------
MCSManager is installed at \"$mcsmanager_install_path\"
Continuing the installation will delete the original MCSManager!
----------------------------------------------------
Installation will continue in 10 seconds, press Ctrl + Z/C to cancel!"
  sleep 10
fi

# Install related software
echo_cyan_n "[+] Installing dependent software(git,tar)... "
if [ -x "$(command -v yum)" ]; then yum install -y git tar > error;
elif [ -x "$(command -v apt-get)" ]; then apt-get install -y git tar > error;
elif [ -x "$(command -v pacman)" ]; then pacman -Syu --noconfirm git tar > error;
elif [ -x "$(command -v zypper)" ]; then zypper --non-interactive install git tar > error;
fi

# Determine whether the relevant software is installed successfully
if [[ -x "$(command -v git)" && -x "$(command -v tar)" ]]
  then
    echo_green "Success"
  else
    echo_red "Failed"
    echo "$error"
    Red_Error "[x] Related software installation failed, please install git and tar packages manually!"
    exit
fi


# Install the Node environment
Install_Node

# Install MCSManager
Install_MCSManager

# Create MCSManager background service
Create_Service
