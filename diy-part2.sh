#!/bin/bash
# 修改默认管理 IP（
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate
