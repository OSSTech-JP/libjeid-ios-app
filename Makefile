.PHONY: build archive

XCODEBUILD := xcodebuild

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
	ios-deploy -d --id bfe675e91534de3ed276bec3cf1dd82d7433e0f1 --bundle build/Release-iphoneos/jeidreader.app

