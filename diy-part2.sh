#!/bin/bash
#
# Copyright (c) 2019-2026 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)

echo "=== 开始执行 diy-part2.sh ==="

# =====================================================================
# 1. 修改默认 LAN IP 为 10.1.1.1/24
# =====================================================================
sed -i 's/lan) ipad=${ipaddr:-"192.168.1.1"}/lan) ipad=${ipaddr:-"10.1.1.1\/24"}/g' package/base-files/files/bin/config_generate

# =====================================================================
# 2. Go 编译环境优化（适配 sing-box 1.13.5）
# =====================================================================
export GOPROXY="https://proxy.golang.org,direct"
export GOFLAGS="-p=2"
export GOGC=40

# 为自定义 sing-box 注入 Go 参数
if [ -d "package/custom/sing-box" ]; then
    echo "→ 为自定义 sing-box 注入 GOGC=40 参数"
    sed -i '/GO_PKG_LDFLAGS_X/a\GO_PKG_VARS:=GOGC=40' package/custom/sing-box/Makefile 2>/dev/null || true
fi

# 兼容 feeds 路径（双保险）
if [ -d "feeds/packages/net/sing-box" ]; then
    sed -i '/GO_PKG_LDFLAGS_X/a\GO_PKG_VARS:=GOGC=40' feeds/packages/net/sing-box/Makefile 2>/dev/null || true
fi

# =====================================================================
# 3. 防火墙相关修复
# =====================================================================
sed -i 's/iptables/iptables-nft/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true

# =====================================================================
# 4. 清理可能冲突的旧文件
# =====================================================================
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/shadowsocksr-libev

# =====================================================================
# 5. 禁用 OpenClash 默认自启
# =====================================================================
sed -i '/uci set openclash.config.enable=1/d' package/feeds/*/luci-app-openclash/root/etc/uci-defaults/luci-openclash 2>/dev/null || true

# =====================================================================
# 6. 创建自定义开机初始化脚本
# =====================================================================
mkdir -p package/base-files/files/etc/uci-defaults

cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-settings
#!/bin/sh
echo "=== 执行自定义初始化设置 ==="

# 锁定 LAN IP 和掩码
uci set network.lan.ipaddr='10.1.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# 设置 Argon 为默认主题
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# 清理可能的锁文件
rm -f /var/run/fw4.lock
rm -f /var/run/luci-reload.lock
rm -f /var/run/config.lock
# 强制清理 sing-box 缓存
rm -rf build_dir/target-x86_64_musl/sing-box-*
rm -rf staging_dir/target-x86_64_musl/root-x86_64/usr/bin/sing-box

echo "自定义设置应用完成！"
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings

echo "========================================"
echo "diy-part2.sh 执行完成！"
echo "→ LAN IP 已设置为 10.1.1.1/24"
echo "→ sing-box 1.13.5 + Tailscale 已优化"
echo "→ Argon 主题已配置"
echo "========================================"
