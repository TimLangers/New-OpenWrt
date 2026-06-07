#!/bin/bash
# Description: OpenWrt DIY script part 2 (Clean & Optimized)

set -e

echo "=== 正在执行 DIY 优化脚本 ==="

# 1. 强制架构防护：防止第三方包修改 .config 架构
echo "=== 检查架构配置 ==="
if grep -q "CONFIG_TARGET_x86_64=y" .config; then
    echo "✓ 架构检测通过：当前为 x86_64"
else
    echo "⚠️ 严重警告：当前检测到的架构不是 x86_64！请检查环境。"
fi

# 2. 修改 LAN IP
sed -i 's/lan) ipad=\${ipaddr:-"192\.168\.1\.1"}/lan) ipad=${ipaddr:-"10.1.1.1"}/g' package/base-files/files/bin/config_generate

# 3. 修复 Golang 编译路径
find feeds/packages -name "Makefile" -type f | xargs -i sed -i 's#../../lang/golang/#$(TOPDIR)/feeds/packages/lang/golang/#g' {}

# 4. 优化 sing-box (仅注入参数，不修改 Makefile 逻辑)
if [ -f "package/custom/sing-box/Makefile" ]; then
    sed -i '/^GO_PKG_LDFLAGS_X/a GO_PKG_VARS:=GOGC=50 CGO_ENABLED=0' package/custom/sing-box/Makefile
fi

# 5. 防火墙与 LuCI 修复
sed -i 's/"iptables"/"iptables-nft"/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true

# 6. 清理可能导致冲突的主题文件 (防止多版本 Argon 冲突)
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 7. 配置 Argon 主题与系统默认值
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/97-theme-config << 'EOF'
#!/bin/sh
uci set luci.main.mediaurlbase='/luci-static/argon'
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit luci
uci commit system
EOF
chmod +x package/base-files/files/etc/uci-defaults/97-theme-config

# 8. 自定义开机初始化脚本
cat > package/base-files/files/etc/uci-defaults/99-custom-settings << 'EOF'
#!/bin/sh
uci set network.lan.ipaddr='10.1.1.1'
uci set network.lan.netmask='255.255.255.0'
uci set system.@system[0].hostname='OpenWrt'
uci commit network
uci commit system
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings

echo "=== DIY 脚本执行完成 ==="
