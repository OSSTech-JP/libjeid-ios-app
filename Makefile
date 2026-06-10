.PHONY: build archive

XCODEBUILD := xcodebuild
DEVELOPMENT_TEAM ?= FC89S46DN3
DEVICE_ID ?= bfe675e91534de3ed276bec3cf1dd82d7433e0f1

BUILD_OPT += DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM)

build:
	$(XCODEBUILD) $(BUILD_OPT) build | xcbeautify

archive:
	$(XCODEBUILD) $(BUILD_OPT) archive | xcbeautify

clean:
	$(XCODEBUILD) $(BUILD_OPT) clean
	rm -rf build

unlock:
	security unlock-keychain login.keychain

install:
	ios-deploy -d --id $(DEVICE_ID) --bundle build/Release-iphoneos/jeidreader.app

