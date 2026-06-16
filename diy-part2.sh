#!/bin/bash

# ==========================================================
# DIY-PART2.SH - 编译后配置脚本
# ==========================================================

# 1. 架构校验
if ! grep -q "CONFIG_TARGET_x86_64=y" .config; then exit 1; fi

# 2. 彻底删除你不需要的插件 (通过在源码目录直接删除对应文件夹)
# 这样即便 .config 里有残留，编译系统也找不到相关文件
rm -rf package/feeds/luci/luci-app-ttyd
rm -rf package/feeds/luci/luci-app-smartdns

# 3. 修改默认 IP 和 主机名
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 4. 统一写入 uci-defaults 自定义设置
# 这是最稳妥的方式，确保首次启动时设置优先级最高
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

# 5. 强制修复 Argon 主题配置 (防止被默认设置回滚)
sed -i 's/luci.main.mediaurlbase=.*/luci.main.mediaurlbase=\/luci-static\/argon/g' feeds/luci/modules/luci-mod-admin-full/root/etc/uci-defaults/luci-mod-admin 2>/dev/null || true

# 6. 最后的清理
rm -rf tmp/
