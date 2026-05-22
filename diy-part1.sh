#!/bin/bash
#
# Copyright (c) 2019-2026 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)

echo "=================================="
echo "开始执行 diy-part1.sh"
echo "=================================="

# =====================================================================
# 【重要】添加自定义 feeds 源（如需要）
# =====================================================================
# 如果你有自定义的 feeds 源，在这里添加
# echo "src-git custom https://github.com/your-username/your-feeds.git" >> feeds.conf.default

# =====================================================================
# sing-box 自定义编译包 (v1.12.5 稳定版)
# =====================================================================
echo "=== 正在准备 sing-box 自定义包 (v1.12.5) ==="

# 创建自定义包目录
mkdir -p package/custom/sing-box

# 创建 Makefile
cat > package/custom/sing-box/Makefile << 'MAKEFILE_EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=sing-box
PKG_VERSION:=1.12.5
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/SagerNet/sing-box/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=skip

PKG_LICENSE:=GPL-3.0-or-later
PKG_MAINTAINER:=SagerNet <https://github.com/SagerNet>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/sagernet/sing-box
GO_PKG_BUILD_PKG:=$(GO_PKG)/cmd/sing-box
GO_PKG_LDFLAGS_X:=$(GO_PKG)/constant.Version=$(PKG_VERSION)

# 【修复】添加 Go 编译优化参数
GO_PKG_VARS:=GOGC=40 CGO_ENABLED=0

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/sing-box
  TITLE:=The universal proxy platform
  SECTION:=net
  CATEGORY:=Network
  URL:=https://sing-box.sagernet.org
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle +kmod-tun
  USERID:=sing-box=5566:sing-box=5566
  PROVIDES:=sing-box
endef

define Package/sing-box/description
  Sing-box is a universal proxy platform.
endef

# 【修复】配置菜单选项
define Package/sing-box/config
  menu "Select build options"
    depends on PACKAGE_sing-box
    config SINGBOX_WITH_TAILSCALE
      bool "Build with Tailscale support"
      default y
    config SINGBOX_WITH_QUIC
      bool "Build with QUIC support"
      default y
    config SINGBOX_WITH_WIREGUARD
      bool "Build with WireGuard support"
      default y
    config SINGBOX_WITH_GVISOR
      bool "Build with gVisor support"
      default y
    config SINGBOX_WITH_UTLS
      bool "Build with uTLS support"
      default y
    config SINGBOX_WITH_CLASH_API
      bool "Build with Clash API support"
      default y
  endmenu
endef

PKG_CONFIG_DEPENDS:= \
  CONFIG_SINGBOX_WITH_TAILSCALE \
  CONFIG_SINGBOX_WITH_QUIC \
  CONFIG_SINGBOX_WITH_WIREGUARD \
  CONFIG_SINGBOX_WITH_GVISOR \
  CONFIG_SINGBOX_WITH_UTLS \
  CONFIG_SINGBOX_WITH_CLASH_API

# 【修复】构建标签（依据配置生成）
GO_PKG_TAGS:=$(subst $(space),$(comma),$(strip \
  $(if $(CONFIG_SINGBOX_WITH_QUIC),with_quic) \
  $(if $(CONFIG_SINGBOX_WITH_UTLS),with_utls) \
  $(if $(CONFIG_SINGBOX_WITH_CLASH_API),with_clash_api) \
  $(if $(CONFIG_SINGBOX_WITH_GVISOR),with_gvisor) \
  $(if $(CONFIG_SINGBOX_WITH_WIREGUARD),with_wireguard) \
  $(if $(CONFIG_SINGBOX_WITH_TAILSCALE),with_tailscale) \
))

define Package/sing-box/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/sing-box $(1)/usr/bin/sing-box
	
	# 【新增】安装配置目录
	$(INSTALL_DIR) $(1)/etc/sing-box
endef

define Package/sing-box/postinst
#!/bin/sh
# 创建 sing-box 用户和组
useradd -r -s /bin/false -d /dev/null sing-box 2>/dev/null || true
chown -R sing-box:sing-box /etc/sing-box 2>/dev/null || true
exit 0
endef

$(eval $(call BuildPackage,sing-box))
MAKEFILE_EOF

echo "✓ sing-box Makefile 已创建"

# =====================================================================
# 创建 sing-box 配置目录结构
# =====================================================================
mkdir -p package/custom/sing-box/files/etc/sing-box
mkdir -p package/custom/sing-box/files/etc/init.d

# 创建初始化脚本
cat > package/custom/sing-box/files/etc/init.d/sing-box << 'INIT_EOF'
#!/bin/sh /etc/rc.common

START=90
STOP=10

USE_PROCD=1
PROG=/usr/bin/sing-box
CONF=/etc/sing-box/config.json

start_service() {
    procd_open_instance
    procd_set_param command $PROG run -c $CONF
    procd_set_param user sing-box
    procd_set_param respawn 3600 5 0
    procd_close_instance
}

stop_service() {
    killall sing-box 2>/dev/null || true
}
INIT_EOF

chmod +x package/custom/sing-box/files/etc/init.d/sing-box
echo "✓ sing-box init 脚本已创建"

# =====================================================================
# 环境变量优化（加快编译速度）
# =====================================================================
export GOPROXY="https://proxy.golang.org,direct"
export GOFLAGS="-p=4"
export GOGC=50

echo "✓ Go 编译环境已优化 (GOGC=50, GOFLAGS=-p=4)"

# =====================================================================
# 清理可能冲突的旧包
# =====================================================================
echo "=== 清理可能冲突的旧包 ==="

# 移除可能存在的冲突包
rm -rf feeds/packages/net/sing-box
rm -rf feeds/telephony
rm -rf feeds/oldpackages

echo "✓ 旧包清理完成"

# =====================================================================
# 修复 feeds 路径（双保险）
# =====================================================================
echo "=== 修复第三方包 Golang 路径 ==="

# 预防性修复（在 Feeds 更新前）
find . -name "Makefile" -type f 2>/dev/null | head -20 | \
  xargs sed -i 's#include.*lang/golang/golang-package.mk#include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk#g'

echo "✓ Golang 包路径预防性修复完成"

# =====================================================================
# 显示脚本执行完成信息
# =====================================================================
echo ""
echo "=================================="
echo "✅ diy-part1.sh 执行完成！"
echo "=================================="
echo "已完成操作："
echo "  ✓ 创建 sing-box 1.12.5 自定义包"
echo "  ✓ 配置 Makefile 和 init 脚本"
echo "  ✓ 优化 Go 编译环境"
echo "  ✓ 清理冲突包"
echo "  ✓ 预防性修复 Golang 路径"
echo ""
echo "下一步: 执行 feeds update/install"
echo "=================================="
