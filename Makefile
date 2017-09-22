#
# Copyright (C) 2017 OpenWrt-AutoRepeate
# Copyright (C) 2017 peter-tank
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=autorepeater
PKG_VERSION:=0.0.1
PKG_RELEASE:=1

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=peter-tank

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/autorepeater/Default
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=AutoRepeater LuCI interface
	URL:=https://github.com/peter-tank/autorepeater
	PKGARCH:=all
	DEPENDS:=+rpcd-mod-iwinfo +jshn +jsonfilter
endef


Package/luci-app-autorepeater = $(Package/autorepeater/Default)

define Package/autorepeater/description
	LuCI Support for $(1).
endef

Package/luci-app-autorepeater/description = $(call Package/autorepeater/description,Pure Script AutoRepeater)

define Package/autorepeater/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for autorepeater"
     /etc/init.d/autorepeater disable
     /etc/init.d/autorepeater stop
    echo "Removing firewall rule for autorepeater"
	  uci -q batch <<-EOF >/dev/null
		delete firewall.autorepeater
		commit firewall
EOF
fi
exit 0
endef

Package/luci-app-autorepeater/prerm = $(Package/autorepeater/prerm)

define Package/autorepeater/conffiles
/etc/config/autorepeater
endef

Package/luci-app-autorepeater/conffiles = $(Package/autorepeater/conffiles)

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/files/luci/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
	$(foreach pa,$(wildcard ${CURDIR}/files/luci/i18n/*.pa), \
		lmotool ${CURDIR}/files/luci/i18n/$(patsubst %.pa,%.lmo,$(notdir $(pa))) $(pa) $(PKG_BUILD_DIR)/$(patsubst %.pa,%.lmo,$(notdir $(pa)));)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/autorepeater/postinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-autorepeater ) && rm -f /etc/uci-defaults/luci-autorepeater
	chmod 755 /etc/init.d/autorepeater >/dev/null 2>&1
	#/etc/init.d/autorepeater enable >/dev/null 2>&1

	uci -q batch <<-EOF >/dev/null
		delete firewall.autorepeater
		set firewall.autorepeater=include
		set firewall.autorepeater.type=script
		set firewall.autorepeater.path=/var/etc/autorepeater.include
		set firewall.autorepeater.reload=0
		commit firewall
EOF
fi
exit 0
endef

Package/luci-app-autorepeater/postinst = $(Package/autorepeater/postinst)

define Package/autorepeater/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/autorepeater.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/autorepeater.*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/autorepeater
	$(INSTALL_DATA) ./files/luci/model/cbi/autorepeater/*.lua $(1)/usr/lib/lua/luci/model/cbi/autorepeater/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/tools
	$(INSTALL_DATA) ./files/luci/tools/*.lua $(1)/usr/lib/lua/luci/tools/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/autorepeater
	$(INSTALL_DATA) ./files/luci/view/autorepeater/*.htm $(1)/usr/lib/lua/luci/view/autorepeater/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/luci-autorepeater $(1)/etc/uci-defaults/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib/autorepeater
	$(INSTALL_BIN) ./files/scan_wifi.sh $(1)/usr/lib/autorepeater/
	$(INSTALL_BIN) ./files/rfkill.sh $(1)/usr/lib/autorepeater/
	$(INSTALL_BIN) ./files/autorepeater_updater.sh $(1)/usr/lib/autorepeater/
	$(INSTALL_DATA) ./files/*.awk $(1)/usr/lib/autorepeater/
	$(INSTALL_DATA) ./files/autorepeater_functions.sh $(1)/usr/lib/autorepeater/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/autorepeater.config $(1)/etc/config/autorepeater
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/autorepeater.init $(1)/etc/init.d/autorepeater
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface/
	$(INSTALL_BIN) ./files/95-upnpc $(1)/etc/hotplug.d/iface/
endef

Package/luci-app-autorepeater/install = $(Package/autorepeater/install)

$(eval $(call BuildPackage,luci-app-autorepeater))
