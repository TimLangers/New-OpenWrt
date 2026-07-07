#!/bin/bash
# ==========================================================
# DIY-PART1.SH - 仅添加必要的插件源
# ==========================================================

# 添加 OpenClash 源码到 feeds 配置文件末尾
echo 'src-git openclash https://github.com/vernesong/OpenClash.git;master' >> feeds.conf.default
