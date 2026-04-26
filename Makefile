include $(TOPDIR)/rules.mk

PKG_NAME:=dejede-control
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Dejede

include $(INCLUDE_DIR)/package.mk

define Package/dejede-control
SECTION:=luci
CATEGORY:=LuCI
TITLE:=Dejede LED Control B1300
DEPENDS:=+luci +luci-base
endef

define Package/dejede-control/description
LuCI custom panel for LED control, monitoring, and system tools on GL.iNet B1300
endef

define Build/Compile
endef

define Package/dejede-control/install
$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/dejede
$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/dejede

```
$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/dejede/control.htm \
	$(1)/usr/lib/lua/luci/view/dejede/control.htm

$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/dejede/control.lua \
	$(1)/usr/lib/lua/luci/controller/dejede/control.lua
```

endef

define Package/dejede-control/postinst
#!/bin/sh
sed -i 's/\r$//' /usr/lib/lua/luci/view/dejede/control.htm
/etc/init.d/uhttpd restart
/etc/init.d/cron restart
rm -rf /tmp/luci-*
exit 0
endef

$(eval $(call BuildPackage,dejede-control))
