#!/bin/bash
# Instala o driver do monitor fantasma e os drivers da Intel (Quick Sync)
apt-get update
apt-get install -y software-properties-common
add-apt-repository universe multiverse -y
apt-get update
apt-get install -y xserver-xorg-video-dummy intel-media-va-driver-non-free mesa-vulkan-drivers libgl1-mesa-dri

# Gera a configuração de vídeo travada no monitor fantasma (Segurança)
cat > /etc/X11/xorg.conf << 'XEOF'
Section "Device"
    Identifier "DummyCard"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Monitor"
    Identifier "DummyMonitor"
    HorizSync 28.0-80.0
    VertRefresh 48.0-120.0
EndSection

Section "Screen"
    Identifier "DummyScreen"
    Device "DummyCard"
    Monitor "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
    EndSubSection
EndSection

Section "InputClass"
    Identifier "Ignore host pointer devices"
    MatchIsPointer "on"
    Option "Ignore" "on"
EndSection

Section "InputClass"
    Identifier "Ignore host keyboard devices"
    MatchIsKeyboard "on"
    Option "Ignore" "on"
EndSection

Section "InputClass"
    Identifier "Sunshine virtual mouse"
    MatchProduct "Mouse passthrough"
    MatchDevicePath "/dev/input/event*"
    Driver "evdev"
    Option "Ignore" "off"
EndSection

Section "InputClass"
    Identifier "Sunshine virtual keyboard"
    MatchProduct "Keyboard passthrough"
    MatchDevicePath "/dev/input/event*"
    Driver "evdev"
    Option "Ignore" "off"
EndSection
XEOF
