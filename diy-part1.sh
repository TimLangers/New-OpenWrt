#!/bin/bash
# ==========================================================
# DIY-PART1.SH - 仅添加必要的插件源
# ==========================================================

# 只保留 OpenClash 源
echo 'src-git openclash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default

# 更新与安装
./scripts/feeds update -a
./scripts/feeds install -a
