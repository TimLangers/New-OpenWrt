#!/bin/bash
# 自动引入 OpenClash 和 PassWall 源码
echo 'src-git openclash https://github.com/vernesong/OpenClash.git;master' >>feeds.conf.default
echo 'src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main' >>feeds.conf.default
echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main' >>feeds.conf.default
