#!/bin/bash
KERNEL_VER="5.15"

# 引入本机预设
svn co https://github.com/WLWolf5/test6/trunk/files
# 引入Patch
svn co https://github.com/WLWolf5/test6/trunk/patch && rm -rf patch/.svn

# 临时修复
sed -i 's|https://source.codeaurora.org/quic|https://git.codelinaro.org/clo|' package/qca/qca-ssdk-shell/Makefile
sed -i 's|https://source.codeaurora.org/quic|https://git.codelinaro.org/clo|' package/qca/nss/qca-nss-drv-64/Makefile
sed -i 's|https://source.codeaurora.org/quic|https://git.codelinaro.org/clo|' package/lean/shortcut-fe/simulated-driver/Makefile
sed -i 's|https://source.codeaurora.org/quic/cc-qrdk|https://git.codelinaro.org/clo/qsdk|' package/qca/nss/qca-nss-ecm-64/Makefile
sed -i 's|https://source.codeaurora.org/quic/cc-qrdk|https://git.codelinaro.org/clo/qsdk|' package/qca/nss/qca-nss-clients-64/Makefile

# 通用

# 修复Package/Makefile编译错误
sed -i s#system/opkg#opkg#g package/Makefile
# 不知道什么优化
sed -i 's/Os/O2 -Wl,--gc-sections/g' include/target.mk
# 修复arm64型号
wget https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/target/linux/generic/hack-5.10/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch -P target/linux/generic/hack-$KERNEL_VER
# 优化toolchain/musl
wget -qO - https://github.com/openwrt/openwrt/commit/8249a8c.patch | patch -p1
# schedutil调度
sed -i '/CONFIG_CPU_FREQ_GOV_ONDEMAND=y/a\CONFIG_CPU_FREQ_GOV_SCHEDUTIL=y' target/linux/ipq807x/config-$KERNEL_VER
sed -i 's/# CONFIG_CPU_FREQ_GOV_POWERSAVE is not set/CONFIG_CPU_FREQ_GOV_POWERSAVE=y/g' target/linux/ipq807x/config-$KERNEL_VER
sed -i 's/# CONFIG_CPU_FREQ_STAT is not set/CONFIG_CPU_FREQ_STAT=y/g' target/linux/ipq807x/config-$KERNEL_VER
# 修改连接数上限
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf
# 设置默认NTP服务器
sed -i "s/0.openwrt.pool.ntp.org/ntp.aliyun.com/g" package/base-files/files/bin/config_generate
sed -i "s/1.openwrt.pool.ntp.org/cn.ntp.org.cn/g" package/base-files/files/bin/config_generate
sed -i "s/2.openwrt.pool.ntp.org/cn.pool.ntp.org/g" package/base-files/files/bin/config_generate
# 添加BBRv2支持(修改package/kernel/linux/modules/netsupport.mk)
wget https://raw.githubusercontent.com/QiuSimons/YAOF/22.03/PATCH/BBRv2/openwrt/package/kernel/linux/files/sysctl-tcp-bbr2.conf -P package/kernel/linux/files
wget -qO - https://github.com/openwrt/openwrt/commit/7db9763.patch | patch -p1
# 优化Linux Ramdom Number Generator
svn co https://github.com/QiuSimons/YAOF/trunk/PATCH/LRNG patch/LRNG && rm -rf patch/LRNG/.svn
cp -f patch/LRNG/* target/linux/generic/hack-$KERNEL_VER
# 添加核心温度的显示 (LEDE-Luci)
sed -i 's|pcdata(boardinfo.system or "?")|luci.sys.exec("uname -m") or "?"|g' feeds/luci/modules/luci-mod-admin-full/luasrc/view/admin_status/index.htm
sed -i 's/or "1"%>/or "1"%> ( <%=luci.sys.exec("expr `cat \/sys\/class\/thermal\/thermal_zone0\/temp` \/ 1000") or "?"%> \&#8451; ) /g' feeds/luci/modules/luci-mod-admin-full/luasrc/view/admin_status/index.htm
# 替换成Firewall4
sed -i "s/firewall/firewall4/g" feeds/luci/applications/luci-app-firewall/Makefile 

# LEDE无需
#echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf

# 可选配置

# 修改默认主机名
#sed -i 's/OpenWrt/Redmi-AX6/g' package/base-files/files/bin/config_generate
# 设置默认ip
#sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate


# TCP流量优化
if [ "$KERNEL_VER" == "5.15" ]; then
    wget https://raw.githubusercontent.com/WLWolf5/test6/main/patch/780-v5.17-tcp-defer-skb-freeing-after-socket-lock-is-released.patch -P target/linux/generic/backport-5.15
elif [ "$KERNEL_VER" == "5.10" ]; then
    wget https://raw.githubusercontent.com/QiuSimons/YAOF/22.03/PATCH/backport/TCP/780-v5.17-tcp-defer-skb-freeing-after-socket-lock-is-released.patch -P target/linux/generic/backport-5.10
fi

# 补充驱动 5.15
if [ "$KERNEL_VER" == "5.15" ]; then
    rm -rf package/qca/firmware/nss-firmware
    rm -rf package/firmware/ath11k-firmware
    
    curl -Lo package/firmware/ipq-wifi/board-redmi_ax6.ipq8074 https://github.com/robimarko/openwrt/raw/ipq807x-5.15-pr-nss-crypto/package/firmware/ipq-wifi/board-redmi_ax6.ipq8074
    svn co https://github.com/robimarko/openwrt/branches/ipq807x-5.15-pr-nss-drv/package/firmware/nss-firmware package/firmware/nss-firmware
    svn co https://github.com/robimarko/openwrt/branches/ipq807x-5.15-pr-nss-drv/package/firmware/ath11k-firmware package/firmware/ath11k-firmware
fi

# TCP-BBRv2 (5.15)
if [ "$KERNEL_VER" == "5.15" ]; then
    cp -f patch/tcp-bbr2/* target/linux/generic/hack-5.15
fi

# Bug修复 (5.10)
if [ "$KERNEL_VER" == "5.10" ]; then
    wget https://raw.githubusercontent.com/WLWolf5/test6/main/patch/104-RFC-ath11k-fix-peer-addition-deletion-error-on-sta-band-migration.patch -P package/kernel/mac80211/patches/ath11k
fi

# 优化内存管理 (5.10)
if [ "$KERNEL_VER" == "5.10" ]; then
    svn co https://github.com/QiuSimons/YAOF/trunk/PATCH/backport/MG-LRU patch/MG-LRU && rm -rf patch/MG-LRU/.svn
    cp -f patch/MG-LRU/* target/linux/generic/pending-5.10
fi

# TCP-BBRv2 (5.10)
if [ "$KERNEL_VER" == "5.10" ]; then
    svn co https://github.com/QiuSimons/YAOF/trunk/PATCH/BBRv2/kernel patch/tcp-bbr2-5.10 && rm -rf patch/tcp-bbr2-5.10/.svn
    cp -f patch/tcp-bbr2-5.10/* target/linux/generic/hack-5.10
fi

# Testing

# 修复tools
rm -rf tools/elfutils
svn co https://github.com/openwrt/openwrt/trunk/tools/elfutils tools/elfutils
rm -rf package/libs/elfutils
svn co https://github.com/openwrt/openwrt/trunk/package/libs/elfutils package/libs/elfutils
sed -i '/patchelf pkgconf/i\tools-y += ucl upx' ./tools/Makefile
sed -i '\/autoconf\/compile :=/i\$(curdir)/upx/compile := $(curdir)/ucl/compile' ./tools/Makefile
svn co https://github.com/Lienol/openwrt/branches/master/tools/ucl tools/ucl
svn co https://github.com/Lienol/openwrt/branches/master/tools/upx tools/upx
wget -qO - https://github.com/openwrt/openwrt/commit/b839f3d5.patch | patch -p1

wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1

# Dnsmasq
rm -rf package/network/services/dnsmasq
svn co https://github.com/openwrt/openwrt/trunk/package/network/services/dnsmasq package/network/services/dnsmasq
curl -Lo feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/dhcp.js https://raw.githubusercontent.com/openwrt/luci/master/modules/luci-mod-network/htdocs/luci-static/resources/view/network/dhcp.js

# ShortCut-FE
wget -qO - https://github.com/coolsnowwolf/lede/commit/e517080.patch | patch -p1
wget -qO - https://raw.githubusercontent.com/QiuSimons/YAOF/22.03/PATCH/firewall/luci-app-firewall_add_sfe_switch.patch | patch -p1

# SSL
rm -rf package/libs/mbedtls
svn co https://github.com/immortalwrt/immortalwrt/trunk/package/libs/mbedtls package/libs/mbedtls
rm -rf package/libs/openssl
svn co https://github.com/immortalwrt/immortalwrt/trunk/package/libs/openssl package/libs/openssl

# 替换Download脚本
curl -Lo scripts/download.pl https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/scripts/download.pl
curl -Lo include/download.mk https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/include/download.mk
sed -i '/unshift/d' scripts/download.pl
sed -i '/mirror02/d' scripts/download.pl

# rpcd
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config

# AutoCore
rm -rf package/lean/autocore
mkdir package/openwrt-add
svn co https://github.com/QiuSimons/OpenWrt-Add/trunk/autocore package/openwrt-add/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/openwrt-add/autocore/files/generic/luci-mod-status-autocore.json
sed -i '/"$threads"/d' package/openwrt-add/autocore/files/x86/autocore


# Openwrt扩展软件包
#git clone https://github.com/kiddin9/openwrt-packages.git package/openwrt-packages
# 扩展软件包冲突处理
#rm -rf package/openwrt-packages/miniupnpd
#rm -rf package/openwrt-packages/miniupnpd-nft
#rm -rf package/openwrt-packages/miniupnpd-iptables
#rm -rf package/openwrt-packages/.github/diy/packages/miniupnpd-iptables
#rm -rf package/openwrt-packages/firewall
#rm -rf package/openwrt-packages/shortcut-fe

# 主题下载
#svn co https://github.com/harry3633/openwrt-package/trunk/lienol/luci-theme-bootstrap-mod package/openwrt-packages/luci-theme-bootstrap-mod
#svn co https://github.com/harry3633/openwrt-package/trunk/lienol/luci-theme-argon-light-mod package/openwrt-packages/luci-theme-argon-light-mod
#svn co https://github.com/harry3633/openwrt-package/trunk/lienol/luci-theme-argon-dark-mod package/openwrt-packages/luci-theme-argon-dark-mod
#svn co https://github.com/a520ass/openwrt-third-packages/trunk/luci-theme-netgear package/openwrt-packages/luci-theme-netgear
#svn co https://github.com/kenzok8/small-package/trunk/luci-theme-argonne package/openwrt-packages/luci-theme-argonne
#svn co https://github.com/kenzok8/small-package/trunk/luci-theme-atmaterial_new package/openwrt-packages/luci-theme-atmaterial_new
#svn co https://github.com/kenzok8/small-package/trunk/luci-theme-neobird package/openwrt-packages/luci-theme-neobird
#svn co https://github.com/kenzok8/small-package/trunk/luci-theme-mcat package/openwrt-packages/luci-theme-mcat
#svn co https://github.com/kenzok8/small-package/trunk/luci-theme-dog package/openwrt-packages/luci-theme-dog
#svn co https://github.com/kenzok8/small-package/trunk/luci-app-argon-config package/openwrt-packages/luci-app-argon-config
#svn co https://github.com/kenzok8/small-package/trunk/luci-app-argonne-config package/openwrt-packages/luci-app-argonne-config
