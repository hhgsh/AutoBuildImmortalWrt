#!/bin/bash

# 1. 导入 Shell 配置中的包名变量
if [ -f "shell/apk-custom-packages.sh" ]; then
    source shell/apk-custom-packages.sh
fi

LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting build25.sh at $(date)" >> $LOGFILE
echo "第三方 apk 软件包: $CUSTOM_PACKAGES"

# 2. 获取 ImageBuilder 的实际绝对路径
IB_DIR="${IMAGEBUILDER_DIR:-$(pwd)}"
PKG_DIR="${IB_DIR}/packages"
FILES_DIR="${IB_DIR}/files"

echo "当前打包根目录: ${IB_DIR}"
mkdir -p "${FILES_DIR}/etc/config"
mkdir -p "${PKG_DIR}"

echo "========================================="
echo "开始下载第三方离线包到 ${PKG_DIR} ..."
echo "========================================="

# 3. 下载 quickfile 离线包
wget -q -P "${PKG_DIR}" https://github.com/sbwml/luci-app-quickfile/releases/download/v1.0.8/luci-app-quickfile_1.0.8-r1_all.apk || true
wget -q -P "${PKG_DIR}" https://github.com/sbwml/luci-app-quickfile/releases/download/v1.0.8/luci-i18n-quickfile-zh-cn_1.0.8-r1_all.apk || true

# 4. 下载 bandix 离线包
wget -q -P "${PKG_DIR}" https://github.com/timsaya/openwrt-bandix/releases/download/v0.12.10/bandix-0.12.10-r1_x86_64.apk || true
wget -q -P "${PKG_DIR}" https://github.com/timsaya/luci-app-bandix/releases/download/v0.12.11/luci-app-bandix_0.12.11-r1_all.apk || true
wget -q -P "${PKG_DIR}" https://github.com/timsaya/luci-app-bandix/releases/download/v0.12.11/luci-i18n-bandix-zh-cn_0.12.11-r1_all.apk || true

# 5. 生成本地 APK 索引，并追加配置
cd "${IB_DIR}"

if command -v apk >/dev/null 2>&1; then
    apk index --allow-untrusted -o "${PKG_DIR}/APKINDEX.tar.gz" "${PKG_DIR}"/*.apk 2>/dev/null || true
fi

# 确保本地 packages 目录加入 repositories.conf
if ! grep -q "${PKG_DIR}" repositories.conf 2>/dev/null; then
    echo "${PKG_DIR}" >> repositories.conf
fi

echo "确认 packages 目录下的文件："
ls -la "${PKG_DIR}"
echo "========================================="

# 6. 创建 pppoe 配置文件
cat << EOF > "${FILES_DIR}/etc/config/pppoe-settings"
enable_pppoe="${ENABLE_PPPOE}"
pppoe_user="${PPPOE_USER}"
pppoe_pass="${PPPOE_PASS}"
EOF

echo "pppoe-settings 已成功写入 ${FILES_DIR}/etc/config/pppoe-settings"

# 7. 执行 ImageBuilder 打包 (关键追加: APK_FLAGS="--allow-untrusted")
echo "========================================="
echo "开始执行 make image 编译打包..."
echo "========================================="

TARGET_PROFILE="generic"
CUSTOM_PACKAGES_CLEAN=$(echo "$CUSTOM_PACKAGES" | xargs)

# 传入 APK_FLAGS 强制解除第三方离线包签名限制
make image PROFILE="${TARGET_PROFILE}" PACKAGES="${CUSTOM_PACKAGES_CLEAN}" FILES="files" APK_FLAGS="--allow-untrusted"

echo "========================================="
echo "打包完成，检查编译出的固件文件："
ls -la bin/targets/x86/64/ || true
echo "========================================="
