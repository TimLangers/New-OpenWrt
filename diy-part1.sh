#!/bin/bash
#
# Copyright (c) 2019-2026 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)

# 1. 清理可能残留的旧源
sed -i '/passwall/d' feeds.conf.default
sed -i '/openclash/d' feeds.conf.default

# 2. 添加最新的 PassWall 官方源
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >> feeds.conf.default
echo 'src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >> feeds.conf.default

# 3. 添加 OpenClash 官方源
echo 'src-git openclash https://github.com/vernesong/OpenClash.git;master' >> feeds.conf.default

# =========================================================
# 4. Argon 主题 + 配置插件（最新优化版）
# =========================================================
echo "=== 正在安装 Argon 主题及配置插件 ==="

# 清理旧版本
rm -rf package/custom/luci-theme-argon
rm -rf package/custom/luci-app-argon-config

# 创建目录
mkdir -p package/custom

# 克隆 Argon 主题（最新 master）
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/custom/luci-theme-argon

# 克隆 Argon 配置插件（强烈推荐）
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/custom/luci-app-argon-config

# =========================================================
# 5. sing-box 自定义版本（解决 Tailscale 依赖问题）
# =========================================================
echo "=== 正在准备自定义 sing-box (v1.13.5) ==="

rm -rf package/custom/sing-box
mkdir -p package/custom/sing-box

cat > package/custom/sing-box/Makefile << 'EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=sing-box
PKG_VERSION:=1.13.5
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/SagerNet/sing-box/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=skip

PKG_LICENSE:=GPL-3.0-or-later
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Van Waholtz <brvphoenix@gmail.com>

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/sagernet/sing-box
GO_PKG_BUILD_PKG:=$(GO_PKG)/cmd/sing-box

GO_PKG_LDFLAGS_X:=$(GO_PKG)/constant.Version=$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include ../../lang/golang/golang-package.mk

define Package/sing-box-default
  TITLE:=The universal proxy platform
  SECTION:=net
  CATEGORY:=Network
  URL:=https://sing-box.sagernet.org
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle +kmod-inet-diag +kmod-tun
  USERID:=sing-box=5566:sing-box=5566
endef

define Package/sing-box
  $(Package/sing-box-default)
  TITLE+= (full)
  VARIANT:=full
  DEFAULT_VARIANT:=1
endef

define Package/sing-box/description
  Sing-box is a universal proxy platform which supports hysteria, SOCKS, Shadowsocks,
  ShadowTLS, Tor, trojan, VLess, VMess, WireGuard and so on.
endef

define Package/sing-box-tiny
  $(Package/sing-box-default)
  TITLE+= (tiny)
  PROVIDES:=sing-box
  VARIANT:=tiny
  CONFLICTS:=sing-box
endef

Package/sing-box-tiny/description:=$(Package/sing-box/description)

define Package/sing-box/config
	menu "Select build options"
		depends on PACKAGE_sing-box
		config SINGBOX_WITH_TAILSCALE
			bool "Build with Tailscale support"
			default y
	endmenu
endef

PKG_CONFIG_DEPENDS:=CONFIG_SINGBOX_WITH_TAILSCALE

ifeq ($(BUILD_VARIANT),tiny)
  GO_PKG_TAGS:=with_quic,with_utls,with_clash_api
else
  GO_PKG_TAGS:=$(subst $(space),$(comma),$(strip \
	with_tailscale with_quic with_utls with_clash_api with_gvisor with_wireguard \
  ))
endif

define Package/sing-box/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/sing-box $(1)/usr/bin/sing-box
endef

Package/sing-box-tiny/install:=$(Package/sing-box/install)

$(eval $(call BuildPackage,sing-box))
$(eval $(call BuildPackage,sing-box-tiny))
EOF

echo "=== diy-part1.sh 执行完成！ ==="
echo "   - Argon 主题 + 配置插件已安装"
echo "   - sing-box 1.13.5 (含 Tailscale) 已准备"
