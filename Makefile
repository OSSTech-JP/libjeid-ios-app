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

