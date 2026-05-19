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

# 4. 安全添加高颜值 Argon 主题（适配全新 LuCI Master 架构）
# 彻底清理所有旧分支残留，防止编译出 ipk 冲突
rm -rf package/feeds/luci/luci-theme-argon
rm -rf package/luci-theme-argon
rm -rf package/luci-app-argon-config

# 不带 -b 参数，直接克隆最新 Master 主分支（原生支持 uCode / APK 格式）
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
