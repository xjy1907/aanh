ARCHS := arm64  # arm64e
TARGET := iphone:clang:15.6:14.0
INSTALL_TARGET_PROCESSES := Books
ENT_PLIST := $(PWD)/supports/entitlements.plist
LAUNCHD_PLIST := $(PWD)/layout/Library/LaunchDaemons/com.nh.hudservices.plist

include $(THEOS)/makefiles/common.mk

GIT_TAG_SHORT := $(shell git describe --tags --always --abbrev=0)
APPLICATION_NAME := Books

Books_USE_MODULES := 0
Books_FILES += $(wildcard sources/*.mm sources/*.m)
Books_FILES += $(wildcard sources/KIF/*.mm sources/KIF/*.m)
Books_FILES += $(wildcard sources/*.swift)
Books_FILES += $(wildcard sources/SPLarkController/*.swift)
Books_FILES += $(wildcard sources/SnapshotSafeView/*.swift)

# App Intents will be built from Xcode.
# Books_FILES += $(wildcard sources/Intents/*.swift)

Books_CFLAGS += -fobjc-arc
Books_CFLAGS += -Iheaders
Books_CFLAGS += -Isources
Books_CFLAGS += -Isources/KIF
Books_CFLAGS += -include supports/hudapp-prefix.pch
MainApplication.mm_CCFLAGS += -std=c++14

Books_SWIFT_BRIDGING_HEADER += supports/hudapp-bridging-header.h

Books_LDFLAGS += -Flibraries

Books_FRAMEWORKS += CoreGraphics CoreServices QuartzCore IOKit UIKit
Books_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices SpringBoardServices
Books_CODESIGN_FLAGS += -Ssupports/entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk

SUBPROJECTS += prefs
ifneq ($(FINALPACKAGE),1)
SUBPROJECTS += memory_pressure
endif

include $(THEOS_MAKE_PATH)/aggregate.mk

before-all::
	$(ECHO_NOTHING)defaults write $(LAUNCHD_PLIST) ProgramArguments -array "$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/Books.app/Books" "-hud" || true$(ECHO_END)
	$(ECHO_NOTHING)plutil -convert xml1 $(LAUNCHD_PLIST)$(ECHO_END)
	$(ECHO_NOTHING)chmod 0644 $(LAUNCHD_PLIST)$(ECHO_END)

before-package::
	$(ECHO_NOTHING)mv -f $(THEOS_STAGING_DIR)/usr/local/bin/memory_pressure $(THEOS_STAGING_DIR)/Applications/Books.app || true$(ECHO_END)
	$(ECHO_NOTHING)rmdir $(THEOS_STAGING_DIR)/usr/local/bin $(THEOS_STAGING_DIR)/usr/local $(THEOS_STAGING_DIR)/usr || true$(ECHO_END)

after-package::
	$(ECHO_NOTHING)mkdir -p packages $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)cp -rp $(THEOS_STAGING_DIR)$(THEOS_PACKAGE_INSTALL_PREFIX)/Applications/Books.app $(THEOS_STAGING_DIR)/Payload$(ECHO_END)
	$(ECHO_NOTHING)defaults delete $(THEOS_STAGING_DIR)/Payload/Books.app/Info.plist CFBundleIconName || true$(ECHO_END)
	$(ECHO_NOTHING)defaults write $(THEOS_STAGING_DIR)/Payload/Books.app/Info.plist CFBundleVersion -string $(shell openssl rand -hex 4)$(ECHO_END)
	$(ECHO_NOTHING)plutil -convert xml1 $(THEOS_STAGING_DIR)/Payload/Books.app/Info.plist$(ECHO_END)
	$(ECHO_NOTHING)chmod 0644 $(THEOS_STAGING_DIR)/Payload/Books.app/Info.plist$(ECHO_END)
	$(ECHO_NOTHING)cd $(THEOS_STAGING_DIR); zip -qr Books_${GIT_TAG_SHORT}.tipa Payload; cd -;$(ECHO_END)
	$(ECHO_NOTHING)mv $(THEOS_STAGING_DIR)/Books_${GIT_TAG_SHORT}.tipa packages/Books_${GIT_TAG_SHORT}.tipa$(ECHO_END)
