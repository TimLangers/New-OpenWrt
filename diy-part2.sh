#!/bin/bash
#
# Copyright (c) 2019-2026 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 1. 修改默认管理 IP (将 192.168.1.1 改为你需要的网段即可)
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 2. 强行将 Argon 修改为默认主题 (初次开机直接生效)
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/modules/luci-base/root/etc/config/luci

# 3. 修复 OpenWrt 25.x 官方源码由于防火墙架构升级造成的额外依赖缺失
# 确保部分旧版插件在 nftables/fw4 架构下也能正常找到防火墙环境
sed -i 's/iptables/iptables-nft/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true

# 4. 清理残留，防止编译过程中出现同名包冲突报错
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

echo "diy-part2.sh 执行完毕！"
