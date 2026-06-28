# acelink-podman

`acelink-podman` is a fork of [Ace Link](https://github.com/blaise-io/acelink) that runs the Ace Stream engine with Podman instead of Docker, including a few quality of life improvements to improve loading and fix some loading issues when acestreams don't emit full metadata.

Play an Ace Stream or Magnet link in your preferred media player by pasting the URL into the menu bar app, or by opening an `acestream://` or `magnet:` link with Ace Link Podman.

<img src="acelink.png" width="350" alt="Ace Link Podman" />

## Requirements

- macOS High Sierra (10.13) or later
- Xcode or the Xcode command line tools
- Podman
- Homebrew, optional, used by the installer only if Podman is missing

If `xcodebuild` is not available yet, install the command line tools first:

```sh
xcode-select --install
```

## Install From Source

Clone the fork and run the installer:

```sh
git clone https://github.com/Swift-Jr/acelink-podman.git
cd acelink-podman
./scripts/install-acelink-podman.sh
```

The script will:

- install Podman with Homebrew if `podman` is missing
- initialize and start the Podman machine when needed
- build the Ace Stream image with `make podman`
- build the macOS app with `xcodebuild`
- copy `Ace Link Podman.app` to your Desktop

Because the app is unsigned, macOS may block the first launch. Control-click `Ace Link Podman.app`, choose **Open**, then confirm.

## Manual Build

If you prefer to run the steps yourself:

```sh
podman machine init
podman machine start
make podman
xcodebuild -scheme 'Ace Link' -configuration Debug -derivedDataPath /tmp/acelink-podman-derived build
cp -R "/tmp/acelink-podman-derived/Build/Products/Debug/Ace Link Podman.app" "$HOME/Desktop/"
```

If your Podman machine already exists, `podman machine init` may report that and can be skipped.

## Media Players

Ace Link Podman lets you choose your own media player. It does not transcode streams, so pick a player that supports common audio and video codecs. VLC, IINA, and MPV are good choices. QuickTime and web browsers play many streams, but not all.

## Ace Stream Server Only

To run just the Ace Stream engine without the macOS app:

```sh
make podman
podman run --platform=linux/amd64 --rm -p 6878:6878 localhost/swift-jr/acelink-podman:latest
```

Then open one of these URLs in a player:

```text
http://127.0.0.1:6878/ace/getstream?id=<acestream id>
http://127.0.0.1:6878/ace/getstream?infohash=<magnet hash>
```

To use a custom `acestream.conf`:

```sh
podman run --platform=linux/amd64 --rm -p 6878:6878 -v "$(pwd)/acestream.conf:/opt/acestream/acestream.conf" localhost/swift-jr/acelink-podman:latest
```