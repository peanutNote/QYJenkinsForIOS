#!/bin/bash

. local.properties

if [[ -z "$OUTPUT_PATH" ]]; then
  echo "You should set the OUTPUT_PATH in local.properties in the current directory"
  exit
fi
 
# 工程名
PRODUCT_NAME="QYJenkinsForIOS"

# 获取最新的版本号
GIT_VERSION=`git rev-parse --short HEAD`

# 时间
CURTIME=`date +%Y%m%d`
 
#获取当前目录
XCODEPROJECT_PATH="../iOS"

# Change the PushConfig plist APS_FOR_PRODUCTION
# /usr/libexec/PlistBuddy -c "Set :APS_FOR_PRODUCTION 1" ${XCODEPROJECT_PATH}/${PRODUCT_NAME}/${PRODUCT_NAME}/PushConfig.plist

# Get Version & Build Number
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${XCODEPROJECT_PATH}/${PRODUCT_NAME}/${PRODUCT_NAME}/Info.plist)
build=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${XCODEPROJECT_PATH}/${PRODUCT_NAME}/${PRODUCT_NAME}/Info.plist)

# Update the build Number
newBuild=$(($build + 1))
echo "Update the version & build number to v$version.$newBuild"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $newBuild" ${XCODEPROJECT_PATH}/${PRODUCT_NAME}/${PRODUCT_NAME}/Info.plist

# Build the ipa
echo "Build the ipa ..."
TEMP_DIR=$(pwd)/tmp
fir build_ipa ${XCODEPROJECT_PATH} -o ${TEMP_DIR} -w -C Release -S ${PRODUCT_NAME}

# publish to fir.im
if [ "$1" != 'skip-firim' ]; then
  echo "Publish to fir.im ..."
  fir publish ${TEMP_DIR}/${PRODUCT_NAME}.ipa
fi

# Backup to dropbox
echo "Backup to dropbox ..."
mv $TEMP_DIR/${PRODUCT_NAME}.ipa ${OUTPUT_PATH}/${PRODUCT_NAME}_release_v${version}.${newBuild}_${GIT_VERSION}_${CURTIME}.ipa

# Remove the tmp
rm -rf ${TEMP_DIR}

# Restore the APS_FOR_PRODUCTION
# /usr/libexec/PlistBuddy -c "Set :APS_FOR_PRODUCTION 0" ${XCODEPROJECT_PATH}/${PRODUCT_NAME}/${PRODUCT_NAME}/PushConfig.plist


