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

# =========================================================
# 1. 精准修改默认管理 IP (只替换指定行，绝不使用全局替换误伤掩码)
# =========================================================
sed -i 's/lan) ipad=${ipaddr:-"192.168.1.1"}/lan) ipad=${ipaddr:-"10.1.1.1"}/g' package/base-files/files/bin/config_generate

# =========================================================
# 2. 修复 OpenWrt 官方源码防火墙架构升级造成的额外依赖缺失
# =========================================================
sed -i 's/iptables/iptables-nft/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true

# =========================================================
# 3. 清理残留，防止编译过程中出现同名包冲突报错
# =========================================================
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# =========================================================
# 4. 终极必杀：直接物理删除引发循环依赖死锁的 libteflon 源码目录
# =========================================================
rm -rf feeds/packages/libs/libteflon
rm -rf package/feeds/packages/libteflon

# =========================================================
# 5. 物理删除已经失效且无用的 shadowsocksr-libev 组件 (防止 PassWall 报错)
# =========================================================
rm -rf feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/shadowsocksr-libev

# =====================================================================
# 6. 核心必杀：强行抹除 OpenClash 的默认开机自启（防止其开机抢占底层网栈憋死防火墙）
# =====================================================================
sed -i '/uci set openclash.config.enable=1/d' package/feeds/*/luci-app-openclash/root/etc/uci-defaults/luci-openclash 2>/dev/null || true

# =====================================================================
# 7. 终极压轴：创建 99-custom-settings 自定义开机脚本 (显式双锁死 IP 与 24位掩码)
# =====================================================================
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-settings
#!/bin/sh

# 📌 A. 显式锁死 LAN 口 IP 为 10.1.1.1，并强制下发 255.255.255.0 标准子网掩码（彻底终结 /32 惨剧）
uci set network.lan.ipaddr='10.1.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# 📌 B. 强行将 Argon 修改为默认主题 (完美适配新版 uCode 架构)
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# 📌 C. 物理蒸发初始化时意外生成的防火墙死锁和网页死锁文件
rm -f /var/run/fw4.lock
rm -f /var/run/luci-reload.lock
rm -f /var/run/config.lock

exit 0
EOF

# 极其重要：赋予该合并后的开机脚本物理可执行权限
chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings

echo "diy-part2.sh 掩码修复及优化补丁全部注入完毕！"
