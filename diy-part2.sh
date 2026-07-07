#!/bin/bash
# ==========================================================
# DIY-PART2.SH - 编译后配置脚本
# ==========================================================

# 1. 架构校验
if ! grep -q "CONFIG_TARGET_x86_64=y" .config; then exit 1; fi

# 2. 彻底删除你不需要的插件 (源码目录删除)
rm -rf package/feeds/luci/luci-app-ttyd
rm -rf package/feeds/luci/luci-app-smartdns

# ----------------------------------------------------------
# 【新增】核心重点：强行注入 OpenClash 及其 25.12 必备依赖
# ----------------------------------------------------------
# 勾选 OpenClash 核心包
echo 'CONFIG_PACKAGE_luci-app-openclash=y' >> .config

# 25.12 固件必须带上 luci-compat，否则 OpenClash 菜单绝对无法显示
echo 'CONFIG_PACKAGE_luci-compat=y' >> .config

# 注入网络、加密及依赖依赖（防止编译时因为缺少依赖而被自动剔除）
echo 'CONFIG_PACKAGE_wget-ssl=y' >> .config
echo 'CONFIG_PACKAGE_curl=y' >> .config
echo 'CONFIG_PACKAGE_ip-full=y' >> .config
echo 'CONFIG_PACKAGE_libcap=y' >> .config
echo 'CONFIG_PACKAGE_libcap-bin=y' >> .config
echo 'CONFIG_PACKAGE_ruby=y' >> .config
echo 'CONFIG_PACKAGE_ruby-yaml=y' >> .config
echo 'CONFIG_PACKAGE_kmod-tun=y' >> .config
# ----------------------------------------------------------

# 3. 修改默认 IP 和 主机名
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 4. 统一写入 uci-defaults 自定义设置
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-custom-settings << 'EOF'
#!/bin/sh
# 修改 LAN 口 IP
uci set network.lan.ipaddr='10.1.1.1'
# 强制设置中文语言
uci set luci.main.lang='zh_hans'
# 强制设置默认主题为 Argon
uci set luci.main.selected_theme='argon'
# 提交更改
uci commit
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings

# 5. 强制修复 Argon 主题配置 (兼容新版路径)
# 25.12 分支的 luci 模块路径可能有所变化，增加对 feeds/luci/ 目录的适配
if [ -d "feeds/luci/modules/luci-base" ]; then
    sed -i 's/luci-static\/bootstrap/luci-static\/argon/g' feeds/luci/modules/luci-base/root/etc/uci-defaults/luci-base 2>/dev/null || true
fi
sed -i 's/luci.main.mediaurlbase=.*/luci.main.mediaurlbase=\/luci-static\/argon/g' feeds/luci/modules/luci-mod-admin-full/root/etc/uci-defaults/luci-mod-admin 2>/dev/null || true

# 6. 最后的清理
rm -rf tmp/
