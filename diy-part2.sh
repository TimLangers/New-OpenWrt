#!/bin/bash
# Description: 修正后的 OpenWrt DIY 脚本

# 1. 强制架构校验 (如果不是 x86_64 立即终止)
if ! grep -q "CONFIG_TARGET_x86_64=y" .config; then
    echo "❌ 错误：检测到当前不是 x86_64 架构，强制停止编译以防止固件异常。"
    exit 1
fi

# 2. 修改默认 LAN IP (使用更通用的 sed 匹配)
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 3. 修复 Golang 路径 (原逻辑保留)
find feeds/packages -name "Makefile" -type f | xargs -i sed -i 's#../../lang/golang/#$(TOPDIR)/feeds/packages/lang/golang/#g' {}

# 4. 清理冲突的主题 (仅保留最干净的安装方式)
rm -rf feeds/luci/themes/luci-theme-argon
# 建议：如果是编译 x86，主题最好通过 feeds 添加或直接放置在 package 目录下，不要 rm 后再进行复杂的操作

# 5. 确保 uci-defaults 脚本优先级最高
# 使用 99- 开头确保它在所有默认设置之后执行
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

echo "=== DIY 脚本执行完成，已强制锁定为 x86_64 ==="
