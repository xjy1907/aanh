ARCHS := arm64 arm64e
TARGET := iphone:clang:15.6:14.0
INSTALL_TARGET_PROCESSES := Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME += BooksHUDPrefs

BooksHUDPrefs_FILES += TSPrefsRootListController.m
BooksHUDPrefs_FRAMEWORKS += UIKit
BooksHUDPrefs_PRIVATE_FRAMEWORKS += Preferences
BooksHUDPrefs_INSTALL_PATH += /Library/PreferenceBundles
BooksHUDPrefs_CFLAGS += -fobjc-arc
BooksHUDPrefs_CFLAGS += -I../supports/

include $(THEOS_MAKE_PATH)/bundle.mk
