#!/bin/bash
#
# Copyright (c) 2019-2026 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)

# =====================================================================
# 1. 精准修改默认管理 IP 并强行注入 24位标准掩码
# =====================================================================
sed -i 's/lan) ipad=${ipaddr:-"192.168.1.1"}/lan) ipad=${ipaddr:-"10.1.1.1\/24"}/g' package/base-files/files/bin/config_generate

# =====================================================================
# 2. Go 编译环境优化（适配新版 sing-box）
# =====================================================================
export GOPROXY="https://proxy.golang.org,direct"
export GOFLAGS="-p=2"                    # 限制并发，防止 OOM
export GOGC=40                           # 增强垃圾回收

# 由于我们使用 package/custom/sing-box，这里修改对应路径
if [ -d "package/custom/sing-box" ]; then
    echo "正在为自定义 sing-box 注入 Go 优化参数..."
    sed -i '/GO_PKG_LDFLAGS_X/a\GO_PKG_VARS:=GOGC=40' package/custom/sing-box/Makefile 2>/dev/null || true
fi

# 同时兼容旧 feeds 路径（防止万一）
if [ -d "feeds/packages/net/sing-box" ]; then
    sed -i '/GO_PKG_LDFLAGS_X/a\GO_PKG_VARS:=GOGC=40' feeds/packages/net/sing-box/Makefile 2>/dev/null || true
fi

# =====================================================================
# 3. 修复 OpenWrt main 分支防火墙依赖问题
# =====================================================================
sed -i 's/iptables/iptables-nft/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true

# =====================================================================
# 4. 清理残留与冲突包
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
# 6. 创建自定义开机设置脚本
# =====================================================================
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-settings
#!/bin/sh
uci set network.lan.ipaddr='10.1.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# 清理锁文件
rm -f /var/run/fw4.lock
rm -f /var/run/luci-reload.lock
rm -f /var/run/config.lock

echo "Custom settings applied successfully."
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings

echo "========================================"
echo "diy-part2.sh 优化补丁已全部注入完毕！"
echo "sing-box 已使用自定义 1.13.5 版本（Tailscale 问题已修复）"
echo "========================================"
