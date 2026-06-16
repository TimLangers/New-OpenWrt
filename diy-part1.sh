#!/bin/bash
# 只负责添加源
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' >> feeds.conf.default
echo 'src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' >> feeds.conf.default
echo 'src-git openclash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default

# 更新与安装
./scripts/feeds update -a
./scripts/feeds install -a
