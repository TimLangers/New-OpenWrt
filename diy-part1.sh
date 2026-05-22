# =========================================================
# sing-box 自定义版本（推荐使用更稳定的 1.12.x）
# =========================================================
echo "=== 正在准备 sing-box (v1.12.5) ==="

rm -rf package/custom/sing-box
mkdir -p package/custom/sing-box

cat > package/custom/sing-box/Makefile << 'EOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=sing-box
PKG_VERSION:=1.12.5
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/SagerNet/sing-box/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=skip

PKG_LICENSE:=GPL-3.0-or-later
PKG_MAINTAINER:=SagerNet

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

GO_PKG:=github.com/sagernet/sing-box
GO_PKG_BUILD_PKG:=$(GO_PKG)/cmd/sing-box
GO_PKG_LDFLAGS_X:=$(GO_PKG)/constant.Version=$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include ../../lang/golang/golang-package.mk

define Package/sing-box
  TITLE:=The universal proxy platform
  SECTION:=net
  CATEGORY:=Network
  URL:=https://sing-box.sagernet.org
  DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle +kmod-tun
  USERID:=sing-box=5566:sing-box=5566
  VARIANT:=full
endef

define Package/sing-box/description
  Sing-box is a universal proxy platform.
endef

define Package/sing-box/config
	menu "Select build options"
		depends on PACKAGE_sing-box
		config SINGBOX_WITH_TAILSCALE
			bool "Build with Tailscale support"
			default y
	endmenu
endef

PKG_CONFIG_DEPENDS:=CONFIG_SINGBOX_WITH_TAILSCALE

GO_PKG_TAGS:=$(subst $(space),$(comma),$(strip \
	with_quic with_utls with_clash_api with_gvisor with_wireguard \
	$(if $(CONFIG_SINGBOX_WITH_TAILSCALE),with_tailscale) \
))

define Package/sing-box/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/sing-box $(1)/usr/bin/sing-box
endef

$(eval $(call BuildPackage,sing-box))
EOF
