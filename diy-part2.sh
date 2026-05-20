#!/bin/bash
#
# Copyright (c) 2019-2026 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# =====================================================================
# 1. 精准修改默认管理 IP 并强行注入 24位标准掩码 (从源头杜绝开机 /32 惨剧)
# =====================================================================
sed -i 's/lan) ipad=${ipaddr:-"192.168.1.1"}/lan) ipad=${ipaddr:-"10.1.1.1\/24"}/g' package/base-files/files/bin/config_generate

# =====================================================================
# 2. 追新死磕：最新版 sing-box 编译环境专项优化与防 OOM 补丁
# =====================================================================
# A) 强制为 Go 编译环境配置全球加速代理（防止 GitHub Actions 容器拉取最新依赖包时断流超时）
export GOPROXY="https://proxy.golang.org,direct"

# B) 限制 Go 自身的编译并发度为 2（防止最新版 sing-box 疯狂挥霍内存导致虚拟机被系统 OOM 强杀）
export GOFLAGS="-p=2"

# C) 提前为 sing-box 注入垃圾回收参数 GOGC=40，让 Go 编译器一边编译一边疯狂释放内存
if [ -d "feeds/packages/net/sing-box" ]; then
    sed -i 's/GO_PKG_VARS:=.*/& GOGC=40/g' feeds/packages/net/sing-box/Makefile 2>/dev/null || true
fi

# D) 彻底粉碎可能残存的旧 Go 工作区和主机缓存，确保完全干净地基于最新 main 分支全新构建
rm -rf .go_work/
rm -rf staging_dir/host/src/go/

# =====================================================================
# 3. 修复 OpenWrt 官方滚动 main 分支防火墙架构升级造成的额外依赖缺失
# =====================================================================
sed -i 's/iptables/iptables-nft/g' feeds/luci/modules/luci-base/root/usr/share/rpcd/acl.d/luci-base.json 2>/dev/null || true

# =====================================================================
# 4. 清理残留与失效组件，防止编译过程中出现同名包冲突报错
# =====================================================================
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/shadowsocksr-libev

# =====================================================================
# 5. 强行抹除 OpenClash 的默认开机自启（防止其开机抢占底层网栈憋死防火墙）
# =====================================================================
sed -i '/uci set openclash.config.enable=1/d' package/feeds/*/luci-app-openclash/root/etc/uci-defaults/luci-openclash 2>/dev/null || true

# =====================================================================
# 6. 终极压轴：创建 99-custom-settings 自定义开机脚本 (显式双锁死 IP 与 24位掩码)
# =====================================================================
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-custom-settings
#!/bin/sh

# 📌 显式锁死 LAN 口 IP 为 10.1.1.1，并强行下发 255.255.255.0 标准子网掩码
uci set network.lan.ipaddr='10.1.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

# 📌 强行将 Argon 修改为默认主题 (完美适配新版 uCode 架构)
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci

# 📌 物理蒸发初始化时意外生成的各类死锁文件
rm -f /var/run/fw4.lock
rm -f /var/run/luci-reload.lock
rm -f /var/run/config.lock

exit 0
EOF

# 极其重要：赋予该开机脚本物理可执行权限
chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings

echo "diy-part2.sh 追新版硬核优化补丁已全部注入完毕！"
