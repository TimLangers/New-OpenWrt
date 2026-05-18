# 1. 修改默认管理 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 2. 强行将 Argon 修改为默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/modules/luci-base/root/etc/config/luci

# 3. 修复 OpenWrt 25.x 官方源码防火墙架构升级造成的额外依赖缺失
sed -i 's/iptables/iptables-nft/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true

# 4. 清理残留，防止编译过程中出现同名包冲突报错
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# 5. 终极必杀：直接物理删除引发循环依赖死锁的 libteflon 源码目录
rm -rf feeds/packages/libs/libteflon
rm -rf package/feeds/packages/libteflon

# =========================================================
# 🔥 新增绝杀：物理删除已经失效且无用的 shadowsocksr-libev 组件
# =========================================================
rm -rf feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/shadowsocksr-libev

echo "diy-part2.sh 执行完毕！"
