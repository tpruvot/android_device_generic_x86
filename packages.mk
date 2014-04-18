#
# Copyright (C) 2012 The Android-x86 Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Common packages for Android-x86 platform.

PRODUCT_PACKAGES := \
    BasicSmsReceiver \
    Development \
    Galaxy4 \
    GlobalTime \
    HoloSpiralWallpaper \
    Launcher3 \
    LiveWallpapers \
    LiveWallpapersPicker \
    MagicSmokeWallpapers \
    NotePad \
    PhaseBeam \
    Provision \
    RSSReader \
    Trebuchet \
    VisualizationWallpapers \
    camera.x86 \
    chat \
    com.android.future.usb.accessory \
    drmserver \
    eject \
    gps.default \
    hwcomposer.x86 \
    icu.dat \
    io_switch \
    libFFmpegExtractor \
    libstagefright_soft_ffmpegadec \
    libstagefright_soft_ffmpegvdec \
    lights.default \
    make_ext4fs \
    parted \
    powerbtnd \
    scp \
    sftp \
    ssh \
    sshd \
    su \
    wacom-input \

PRODUCT_PACKAGES += \
    badblocks \
    e2fsck \
    mke2fs \
    mkntfs \
    mount.exfat \
    ntfs-3g \
    ntfsfix \
    resize2fs \
    tune2fs \

# Third party apps
PRODUCT_PACKAGES += \
    AndroidTerm \
    FileManager \
    LIME \
