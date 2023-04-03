#!/bin/bash
KERNEL_VER="5.15"

# 引入本机预设
svn co https://github.com/WLWolf5/test6/trunk/files
# 引入Patch
svn co https://github.com/WLWolf5/test6/trunk/patch && rm -rf patch/.svn

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

# 追加优化参数
# 专属
echo -e "net.netfilter.nf_conntrack_max=65535\nnet.netfilter.nf_conntrack_expect_max=16384\nnet.netfilter.nf_conntrack_buckets=16384" >> package/kernel/linux/files/sysctl-nf-conntrack.conf
# 通用
echo -e "net.ipv4.tcp_tw_reuse = 1\nnet.ipv4.tcp_tw_recycle = 0\nnet.ipv4.tcp_fastopen = 3\nnet.ipv4.tcp_slow_start_after_idle = 0\nfs.file-max = 51200\nnet.ipv4.ip_local_port_range = 10000 65000" >> package/kernel/linux/files/sysctl-nf-conntrack.conf

# 可选配置

# 修改默认主机名
#sed -i 's/OpenWrt/Redmi-AX6/g' package/base-files/files/bin/config_generate
# 设置默认ip
#sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# 追加软件包
mkdir package/openwrt-add
svn co https://github.com/immortalwrt/immortalwrt/trunk/package/emortal/ipv6-helper package/openwrt-add/ipv6-helper
svn co https://github.com/immortalwrt/immortalwrt/trunk/package/emortal/default-settings package/openwrt-add/default-settings


# TCP流量优化
wget https://raw.githubusercontent.com/WLWolf5/test6/main/patch/780-v5.17-tcp-defer-skb-freeing-after-socket-lock-is-released.patch -P target/linux/generic/backport-5.15

# TCP-BBRv2 (5.15)
cp -f patch/tcp-bbr2/* target/linux/generic/hack-5.15


# 修复 Tools
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
#wget -qO - https://github.com/coolsnowwolf/lede/commit/e517080.patch | patch -p1
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
mkdir package/openwrt-add
svn co https://github.com/QiuSimons/OpenWrt-Add/trunk/autocore package/openwrt-add/autocore
sed -i 's/"getTempInfo" /"getTempInfo", "getCPUBench", "getCPUUsage" /g' package/openwrt-add/autocore/files/generic/luci-mod-status-autocore.json
sed -i '/"$threads"/d' package/openwrt-add/autocore/files/x86/autocore

# nftable-fullcone支持
svn co https://github.com/kiddin9/openwrt-packages/trunk/fullconenat-nft package/openwrt-add/fullconenat-nft
