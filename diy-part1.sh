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

# 1. 清理可能残留的旧源（防报错）
sed -i '/passwall/d' feeds.conf.default
sed -i '/openclash/d' feeds.conf.default

# 2. 最新的 Openwrt-Passwall 官方群组源（每日同步，目前最稳）
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >>feeds.conf.default
echo 'src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >>feeds.conf.default

# 3. 保持 OpenClash 官方源码仓库
echo 'src-git openclash https://github.com/vernesong/OpenClash.git;master' >>feeds.conf.default

# 4. 【核心修复】安全注入最新 Master 架构 Argon 主题
# 直接克隆到自定义目录 custom/themes 下，这样归类更清晰，且绝不会与 package 根目录发生结构冲突
rm -rf package/custom/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git package/custom/luci-theme-argon
