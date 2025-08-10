#!/bin/bash

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to create user
create_user() {
    echo "Please visit http://remotedesktop.google.com/headless and copy the command after Authentication"
    read -p "Paste the CRD SSH command here: " CRD
    echo "Creating User and Setting it up"
    username="disala"
    password="root"
    Pin="123456"
    
    useradd -m "$username"
    adduser "$username" sudo
    echo "$username:$password" | sudo chpasswd
    sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd

    # Add PATH update to .bashrc of the new user
    echo 'export PATH=$PATH:/home/user/.local/bin' >> /home/"$username"/.bashrc
    su - "$username" -c "source ~/.bashrc"

    echo "User '$username' created and configured."
}

# Extra storage setup
setup_storage() {
    mkdir -p /storage
    chmod 777 /storage
    chown "$username":"$username" /storage
    mkdir -p /home/"$username"/storage
    mount --bind /storage /home/"$username"/storage
}

# Function to install and configure RDP
setup_rdp() {
    echo "Google Chrome Installing"
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    dpkg --install google-chrome-stable_current_amd64.deb
    apt install --assume-yes --fix-broken
    
    echo "Installing Firefox ESR"
    add-apt-repository ppa:mozillateam/ppa -y  
    apt update
    apt install --assume-yes firefox-esr
    apt install --assume-yes dbus-x11 dbus 

    echo "Installing dependencies"
    apt update
    add-apt-repository universe -y
    apt install --assume-yes xvfb xserver-xorg-video-dummy xbase-clients python3-packaging python3-psutil python3-xdg libgbm1 libutempter0 libfuse2 nload qbittorrent ffmpeg gpac fonts-lklug-sinhala
    sudo apt update && sudo apt install -y tmate

    echo "Installing Desktop Environment"
    apt install --assume-yes xfce4 desktop-base xfce4-terminal xfce4-session
    echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session
    apt remove --assume-yes gnome-terminal
    apt install --assume-yes xscreensaver
    systemctl disable lightdm.service

    echo "Installing Chrome Remote Desktop"
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg --install chrome-remote-desktop_current_amd64.deb
    apt install --assume-yes --fix-broken

    echo "Finalizing"
    adduser "$username" chrome-remote-desktop
    curl -s -L -k -o xfce-shapes.svg https://raw.githubusercontent.com/The-Disa1a/Cloud-Shell-GCRD/refs/heads/main/Wall/xfce-shapes.svg
    sudo mv xfce-shapes.svg /usr/share/backgrounds/xfce/
    echo "Wallpaper Changed"
    
    su - "$username" -c "$CRD --pin=$Pin"
    service chrome-remote-desktop start
    setup_storage "$username"

    echo "RDP setup completed"
}

# Execute functions
create_user
setup_rdp

