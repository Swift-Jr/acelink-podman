VERSION := $(shell cat VERSION)
APP_NAME ?= Ace Link Podman
ARCHIVEDIR ?= $(CURDIR)/builds/archives/Ace.Link.Podman.$(VERSION).xcarchive
RELEASEDIR ?= $(CURDIR)/builds/Ace.Link.Podman.$(VERSION)
PODMAN_IMAGE ?= localhost/swift-jr/acelink-podman
PODMAN_PLATFORM ?= linux/amd64

podman:
	# Create podman image
	podman build . --file Containerfile --platform=$(PODMAN_PLATFORM) --tag $(PODMAN_IMAGE):$(VERSION) --tag $(PODMAN_IMAGE):latest

build:
	# Create a build
	sed -i '' 's/[0-9]\.[0-9]\.[0-9]/$(VERSION)/g' README.md
	agvtool new-marketing-version $(VERSION)
	xcodebuild -scheme 'Ace Link' archive -archivePath $(ARCHIVEDIR)

tag:
	# Create a new release tag
	git tag $(VERSION)
	git push origin --tags

release:
	# Create a new release DMG from the latest build
	rm -rf $(RELEASEDIR)
	mkdir -p $(RELEASEDIR)
	cp -R '$(ARCHIVEDIR)/Products/Applications/$(APP_NAME).app' $(RELEASEDIR)
	ln -s /Applications $(RELEASEDIR)/Applications
	hdiutil create -volname "$(APP_NAME) $(VERSION)" -srcfolder $(RELEASEDIR) -ov -format UDZO $(RELEASEDIR).dmg
	rm -rf $(RELEASEDIR)
	open -a finder $(CURDIR)/builds
	open https://github.com/Swift-Jr/acelink-podman/releases/new
