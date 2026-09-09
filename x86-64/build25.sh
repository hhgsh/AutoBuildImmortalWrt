#!/bin/bash

# Log file for debugging
source shell/apk-custom-packages.sh
echo "第三方apk软件包: $CUSTOM_PACKAGES"

LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

# 1. 获取 ImageBuilder 的实际绝对路径（兼容无 Docker 的 build-free 和 Docker 环境）
IB_DIR="${IMAGEBUILDER_DIR:-$(pwd)}"
PKG_DIR="${IB_DIR}/packages"
FILES_DIR="${IB_DIR}/files"

echo "当前打包根目录: ${IB_DIR}"

mkdir -p "${FILES_DIR}/etc/config"
mkdir -p "${PKG_DIR}"

echo "========================================="
echo "开始下载第三方离线包到 ${PKG_DIR} ..."
echo "========================================="

# 2. 下载 quickfile 离线包到正确位置
wget -q -P "${PKG_DIR}" https://github.com/sbwml/luci-app-quickfile/releases/download/v1.0.8/luci-app-quickfile_1.0.8-r1_all.apk || true
wget -q -P "${PKG_DIR}" https://github.com/sbwml/luci-app-quickfile/releases/download/v1.0.8/luci-i18n-quickfile-zh-cn_1.0.8-r1_all.apk || true

# 3. 下载 bandix 离线包到正确位置
wget -q -P "${PKG_DIR}" https://github.com/timsaya/openwrt-bandix/releases/download/v0.12.10/bandix-0.12.10-r1_x86_64.apk || true
wget -q -P "${PKG_DIR}" https://github.com/timsaya/luci-app-bandix/releases/download/v0.12.11/luci-app-bandix_0.12.11-r1_all.apk || true
wget -q -P "${PKG_DIR}" https://github.com/timsaya/luci-app-bandix/releases/download/v0.12.11/luci-i18n-bandix-zh-cn_0.12.11-r1_all.apk || true

# 4. 为 apk 生成标准的本地索引文件 APKINDEX.tar.gz (ImmortalWrt 25.12 必须)
if command -v apk >/dev/null 2>&1; then
    apk index --allow-untrusted -o "${PKG_DIR}/APKINDEX.tar.gz" "${PKG_DIR}"/*.apk 2>/dev/null || true
fi

echo "确认 packages 目录下的文件："
ls -la "${PKG_DIR}"
echo "========================================="

# 创建 pppoe 配置文件
cat << EOF > "${FILES_DIR}/etc/config/pppoe-settings"
enable_pppoe="${ENABLE_PPPOE}"
pppoe_user="${PPPOE_USER}"
pppoe_pass="${PPPOE_PASS}"
EOF

echo "pppoe-settings 已成功写入 ${FILES_DIR}/etc/config/pppoe-settings"

# =========================================================
# 执行真正的 ImageBuilder 打包
# =========================================================
echo "========================================="
echo "开始执行 make image 编译打包..."
echo "========================================="

# x86_64 架构固定的 PROFILE 名称必须是 generic
TARGET_PROFILE="generic"

# 切换到 ImageBuilder 目录下执行编译
cd "${IB_DIR}"

# 执行打包
make image PROFILE="${TARGET_PROFILE}" PACKAGES="${CUSTOM_PACKAGES}" FILES="files"

echo "========================================="
echo "打包完成，检查编译出的固件文件："
ls -la bin/targets/x86/64/ || true
echo "========================================="
