#!/bin/bash

# 修复Package/Makefile编译错误
sed -i s#system/opkg#opkg#g package/Makefile
# 本机预设
#svn co https://github.com/WLWolf5/wrtcompiler/trunk/config files
# 个人Patch
#svn co https://github.com/WLWolf5/wrtcompiler/trunk/patch

# 设置为schedutil调度(根据内核修改版本)
sed -i '/CONFIG_CPU_FREQ_GOV_ONDEMAND=y/a\CONFIG_CPU_FREQ_GOV_SCHEDUTIL=y' target/linux/ipq807x/config-5.15
sed -i 's/# CONFIG_CPU_FREQ_GOV_POWERSAVE is not set/CONFIG_CPU_FREQ_GOV_POWERSAVE=y/g' target/linux/ipq807x/config-5.15
sed -i 's/# CONFIG_CPU_FREQ_STAT is not set/CONFIG_CPU_FREQ_STAT=y/g' target/linux/ipq807x/config-5.15
# 修改连接数上限
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf
# 设置默认NTP服务器
sed -i "s/0.openwrt.pool.ntp.org/ntp.aliyun.com/g" package/base-files/files/bin/config_generate
sed -i "s/1.openwrt.pool.ntp.org/cn.ntp.org.cn/g" package/base-files/files/bin/config_generate
sed -i "s/2.openwrt.pool.ntp.org/cn.pool.ntp.org/g" package/base-files/files/bin/config_generate

# 优化

#不知道什么优化
sed -i 's/Os/O2 -Wl,--gc-sections/g' include/target.mk
#改动toolchain/musl/common.mk
wget -qO - https://github.com/openwrt/openwrt/commit/8249a8c.patch | patch -p1
# fstool patch
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1

#TCP BBRv2
curl -LO https://raw.githubusercontent.com/QiuSimons/YAOF/22.03/PATCH/BBRv2/openwrt/package/kernel/linux/files/sysctl-tcp-bbr2.conf
cp -f sysctl-tcp-bbr2.conf package/kernel/linux/files
svn co https://github.com/WLWolf5/wrtcompiler/trunk/patch/tcp-bbr2 patch/tcp-bbr2
rm -rf patch/tcp-bbr2/.svn
#rm -rf tcp-bbr2/693-08-net-tcp_bbr-v2-introduce-ca_ops-skb_marked_lost-CC-m.patch
#rm -rf tcp-bbr2/693-14-net-tcp-re-generalize-TSO-sizing-in-TCP-CC-module-AP.patch
#rm -rf tcp-bbr2/693-16-net-tcp_bbr-v2-BBRv2-bbr2-congestion-control-for-Lin.patch
#rm -rf tcp-bbr2/693-17-net-tcp_bbr-v2-remove-unnecessary-rs.delivered_ce-lo.patch
#rm -rf tcp-bbr2/693-18-net-tcp_bbr-v2-remove-field-bw_rtts-that-is-unused-i.patch
#rm -rf tcp-bbr2/693-19-net-tcp_bbr-v2-remove-cycle_rand-parameter-that-is-u.patch
#rm -rf tcp-bbr2/693-20-net-tcp_bbr-v2-don-t-assume-prior_cwnd-was-set-enter.patch
#rm -rf tcp-bbr2/693-21-net-tcp_bbr-v2-Fix-missing-ECT-markings-on-retransmi.patch
#package/kernel/linux/modules/netsupport.mk添加bbr2支持
wget -qO - https://github.com/openwrt/openwrt/commit/7db9763.patch | patch -p1


# 修改默认主机名
#sed -i 's/OpenWrt/Redmi-AX6/g' package/base-files/files/bin/config_generate
# 设置默认ip
#sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

#补充驱动
#svn co https://github.com/Boos4721/openwrt/trunk/package/firmware/ath11k-board package/openwrt-packages/ath11k-board

# Openwrt扩展软件包
#git clone https://github.com/kiddin9/openwrt-packages.git package/openwrt-packages

# 扩展软件包冲突处理
#rm -rf package/openwrt-packages/miniupnpd
#rm -rf package/openwrt-packages/miniupnpd-nft
#rm -rf package/openwrt-packages/miniupnpd-iptables
#rm -rf package/openwrt-packages/.github/diy/packages/miniupnpd-iptables
#rm -rf package/openwrt-packages/firewall
#rm -rf package/openwrt-packages/shortcut-fe

#Custom Theme
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
