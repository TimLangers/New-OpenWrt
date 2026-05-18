#!/bin/bash
#
# Copyright (c) 2019-2026 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# 1. 最新的 Openwrt-Passwall 官方群组源
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >>feeds.conf.default
echo 'src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >>feeds.conf.default

# 2. 保持 OpenClash 官方源码仓库
echo 'src-git openclash https://github.com/vernesong/OpenClash.git;master' >>feeds.conf.default

# 3. 添加高颜值 Argon 主题及其设置插件源码
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/downloads/luci-theme-argon
git clone https://github.com/jerrykuku/luci-app-argon-config.git package/downloads/luci-app-argon-config
