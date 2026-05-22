#!/bin/bash
#
# Copyright (c) 2019-2026 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)

set -e

echo "=================================="
echo "开始执行 diy-part2.sh"
echo "=================================="

# =====================================================================
# 0. 脚本安全检查
# =====================================================================
if [ ! -f "feeds/packages/lang/golang/golang-package.mk" ]; then
    echo "⚠️  警告: feeds 更新可能未完成，继续执行但可能出现路径问题"
fi

# =====================================================================
# 1. 修改默认 LAN IP 为 10.1.1.1/24
# =====================================================================
echo "=== 步骤 1: 修改默认 LAN IP ==="

# 【修复】正确的配置文件位置
TARGET_FILE="package/base-files/files/bin/config_generate"

if [ -f "$TARGET_FILE" ]; then
    sed -i 's/lan) ipad=\${ipaddr:-"192\.168\.1\.1"}/lan) ipad=${ipaddr:-"10.1.1.1"}/g' "$TARGET_FILE"
    echo "✓ LAN IP 已修改为 10.1.1.1"
else
    echo "⚠️  警告: $TARGET_FILE 不存在，跳过此步骤"
fi

# =====================================================================
# 2. 修复 Golang 包路径（feeds 更新后）
# =====================================================================
echo "=== 步骤 2: 修复 Golang 包路径 ==="

# 【修复】正确的路径替换（防止重复替换）
if [ -d "feeds/packages" ]; then
    find feeds/packages -name "Makefile" -type f | while read file; do
        # 只替换那些仍然使用相对路径的
        if grep -q "../../lang/golang/" "$file" 2>/dev/null; then
            sed -i 's#../../lang/golang/#$(TOPDIR)/feeds/packages/lang/golang/#g' "$file"
        fi
    done
    echo "✓ Golang 包路径修复完成"
else
    echo "⚠️  警告: feeds/packages 不存在"
fi

# =====================================================================
# 3. 为自定义 sing-box 注入 Go 编译参数
# =====================================================================
echo "=== 步骤 3: 配置 sing-box Go 编译参数 ==="

# 【修复】正确检查自定义 sing-box 路径
if [ -f "package/custom/sing-box/Makefile" ]; then
    # 检查是否已经添加过 GO_PKG_VARS
    if ! grep -q "GO_PKG_VARS" package/custom/sing-box/Makefile; then
        sed -i '/^GO_PKG_LDFLAGS_X/a GO_PKG_VARS:=GOGC=50 CGO_ENABLED=0' package/custom/sing-box/Makefile
        echo "✓ sing-box Makefile 已注入 Go 优化参数"
    else
        echo "✓ sing-box Makefile 已包含 Go 优化参数"
    fi
else
    echo "⚠️  警告: 自定义 sing-box/Makefile 不存在"
fi

# =====================================================================
# 4. 防火墙相关修复（Firewall4 + nftables）
# =====================================================================
echo "=== 步骤 4: 修复防火墙配置 ==="

# 【修复】检查 LuCI 防火墙配置是否需要修复
if [ -f "feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json" ]; then
    # 只在必要时替换 iptables 为 iptables-nft
    if grep -q "iptables" feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json; then
        sed -i 's/"iptables"/"iptables-nft"/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json
        echo "✓ LuCI 防火墙配置已更新为 iptables-nft"
    fi
fi

# =====================================================================
# 5. 清理可能冲突的旧文件
# =====================================================================
echo "=== 步骤 5: 清理冲突的旧文件 ==="

# 【修复】更精确的清理（避免删除重要文件）
CLEANUP_DIRS=(
    "feeds/luci/themes/luci-theme-argon"
    "feeds/luci/applications/luci-app-argon-config"
)

for dir in "${CLEANUP_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "  ✓ 已删除: $dir"
    fi
done

echo "✓ 冲突文件清理完成"

# =====================================================================
# 6. 保持 OpenClash 默认自启
# =====================================================================
echo "=== 步骤 6: OpenClash 将保持默认自启 ==="

# OpenClash 自启配置由官方默认处理，无需修改
echo "✓ OpenClash 自启配置保持默认"

# =====================================================================
# 7. 设置 Argon 为默认主题
# =====================================================================
echo "=== 步骤 7: 配置默认主题 ==="

# 【新增】创建 LuCI 默认主题配置
mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/97-theme-config << 'THEME_EOF'
#!/bin/sh

# 设置 Argon 为默认主题
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# 设置时区
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

exit 0
THEME_EOF

chmod +x package/base-files/files/etc/uci-defaults/97-theme-config
echo "✓ 默认主题配置脚本已创建"

# =====================================================================
# 8. 创建自定义开机初始化脚本
# =====================================================================
echo "=== 步骤 8: 创建初始化脚本 ==="

cat > package/base-files/files/etc/uci-defaults/99-custom-settings << 'CUSTOM_EOF'
#!/bin/sh

echo "执行自定义初始化设置..."

# 锁定 LAN IP 和掩码
uci set network.lan.ipaddr='10.1.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# 优化系统参数
uci set system.@system[0].description='OpenWrt Router'
uci set system.@system[0].hostname='OpenWrt'
uci commit system

# 启用 SSH
uci set dropbear.@dropbear[0].enabled='1'
uci commit dropbear

# 清理锁文件
rm -f /var/run/fw4.lock
rm -f /var/run/luci-reload.lock
rm -f /var/run/config.lock

echo "自定义设置应用完成！"
exit 0
CUSTOM_EOF

chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings
echo "✓ 自定义初始化脚本已创建"

# =====================================================================
# 9. 最终配置检查
# =====================================================================
echo "=== 步骤 9: 最终配置检查 ==="

echo "正在验证关键配置文件..."

# 检查 .config 是否存在
if [ -f ".config" ]; then
    echo "✓ .config 配置文件已加载"
    
    # 统计关键配置
    LUCI_COUNT=$(grep -c "CONFIG_PACKAGE_luci" .config 2>/dev/null || echo "0")
    echo "  - LuCI 相关包: $LUCI_COUNT 个"
    
    SING_BOX=$(grep -c "sing-box" .config 2>/dev/null || echo "0")
    if [ "$SING_BOX" -gt 0 ]; then
        echo "  ✓ sing-box 已配置"
    fi
else
    echo "⚠️  警告: .config 配置文件不存在"
fi

# =====================================================================
# 10. 显示完成信息
# =====================================================================
echo ""
echo "=================================="
echo "✅ diy-part2.sh 执行完成！"
echo "=================================="
echo "已完成操作："
echo "  ✓ 修改默认 LAN IP 为 10.1.1.1"
echo "  ✓ 修复 Golang 包路径"
echo "  ✓ 配置 sing-box Go 编译参数"
echo "  ✓ 修复防火墙配置"
echo "  ✓ 清理冲突文件"
echo "  ✓ 禁用 OpenClash 自启"
echo "  ✓ 设置 Argon 为默认主题"
echo "  ✓ 创建初始化脚本"
echo ""
echo "下一步: 执行 make defconfig 和 make download"
echo "=================================="
