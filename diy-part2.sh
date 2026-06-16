#!/bin/bash
# 在此处执行你之前写在 part1 里的修改逻辑
# 1. 架构校验 (可以保留)
if ! grep -q "CONFIG_TARGET_x86_64=y" .config; then exit 1; fi

# 2. 修改 IP 和 主机名
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 3. 写入 uci-defaults
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-custom-settings << 'EOF'
#!/bin/sh
uci set network.lan.ipaddr='10.1.1.1'
uci set system.@system[0].hostname='OpenWrt'
uci commit network
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings
# 强制设置默认主题为 argon
sed -i 's/luci.main.mediaurlbase=\/luci-static\/bootstrap/luci.main.mediaurlbase=\/luci-static\/argon/g' feeds/luci/modules/luci-mod-admin-full/root/etc/uci-defaults/luci-mod-admin
# 或者更直接的通过 uci-defaults 强制修改
echo "uci set luci.main.lang=zh_hans" >> package/base-files/files/etc/uci-defaults/99-custom-settings
echo "uci set luci.themes.Argon=argon" >> package/base-files/files/etc/uci-defaults/99-custom-settings
echo "uci set luci.main.mediaurlbase=/luci-static/argon" >> package/base-files/files/etc/uci-defaults/99-custom-settings
