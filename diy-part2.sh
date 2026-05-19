#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# =========================================================
# 1. 修改默认管理 IP (适配 2025/2026 最新源码新路径)
# =========================================================
sed -i 's/192.168.1.1/10.1.1.1/g' target/linux/base-files/image/config_generate

# =========================================================
# 2. 强行将 Argon 修改为默认主题 (新版 uCode 架构完美兼容方案)
# =========================================================
# 由于新版去掉了旧的默认 config 配置文件，我们用一个一行命令的开机初始化脚本来搞定，100% 成功
mkdir -p package/base-files/files/etc/uci-defaults
echo "uci set luci.main.mediaurlbase='/luci-static/argon' && uci commit luci" > package/base-files/files/etc/uci-defaults/99-default-theme

# =========================================================
# 3. 修复 OpenWrt 官方源码防火墙架构升级造成的额外依赖缺失
# =========================================================
sed -i 's/iptables/iptables-nft/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true

# =========================================================
# 4. 清理残留，防止编译过程中出现同名包冲突报错
# =========================================================
# 强制删掉 feeds 里的旧 argon，配合你的 diy-part1 完美无缝衔接
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config

# =========================================================
# 5. 终极必杀：直接物理删除引发循环依赖死锁的 libteflon 源码目录
# =========================================================
rm -rf feeds/packages/libs/libteflon
rm -rf package/feeds/packages/libteflon

# =========================================================
# 6. 物理删除已经失效且无用的 shadowsocksr-libev 组件 (防止 PassWall 报错)
# =========================================================
rm -rf feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/shadowsocksr-libev

echo "diy-part2.sh 执行完毕！"
