.PHONY: build archive

XCODEBUILD := xcodebuild

build:
	$(XCODEBUILD) $(BUILD_OPT) build | xcpretty

archive:
	$(XCODEBUILD) $(BUILD_OPT) archive | xcpretty

clean:
	$(XCODEBUILD) $(BUILD_OPT) clean
	rm -rf build

unlock:
	security unlock-keychain login.keychain

