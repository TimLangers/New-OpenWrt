#!/bin/bash
# Description: OpenWrt DIY script part 1 (Clean & Optimized)
set -e

echo "=== 正在执行 DIY 优化脚本 part1 ==="

# ==================== 关键修复：先生成 .config ====================
if [ ! -f .config ]; then
    echo "⚠️ 未检测到 .config 文件，正在生成默认配置..."
    make defconfig
fi

# 1. 强制架构防护
echo "=== 检查架构配置 ==="
if grep -q "CONFIG_TARGET_x86_64=y" .config; then
    echo "✓ 架构检测通过：当前为 x86_64"
else
    echo "⚠️ 严重警告：检测到当前架构不是 x86_64！正在强制停止..."
    exit 1
fi

# 2. 修改 LAN IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 3. 修复 Golang 编译路径
find feeds/packages -name "Makefile" -type f | xargs -i sed -i 's#../../lang/golang/#$(TOPDIR)/feeds/packages/lang/golang/#g' {} 2>/dev/null || true

# 4. 优化 sing-box（如果存在）
if [ -f "package/custom/sing-box/Makefile" ]; then
    sed -i '/^GO_PKG_LDFLAGS_X/a GO_PKG_VARS:=GOGC=50 CGO_ENABLED=0' package/custom/sing-box/Makefile
fi

# 5. 防火墙与 LuCI 修复 + 清理
sed -i 's/"iptables"/"iptables-nft"/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 6. uci-defaults 设置
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-custom-settings << 'EOF'
#!/bin/sh
uci set network.lan.ipaddr='10.1.1.1'
uci set network.lan.netmask='255.255.255.0'
uci set system.@system[0].hostname='OpenWrt'
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit network
uci commit system
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings

echo "=== DIY part1 脚本执行完成 ==="
