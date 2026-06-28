import Cocoa
import Foundation
import os

class PodmanRequiredMenu: PartialMenu {
    private let statusItem = NSMenuItem(
        title: "Podman is required to play streams",
        action: nil,
        keyEquivalent: ""
    )

    override public var items: [NSMenuItem] {
        [statusItem, NSMenuItem.separator()]
    }

    override init() {
        super.init()
        statusItem.isEnabled = false
    }

    override func update(canPlay: Bool) {
        for item in items {
            item.isHidden = canPlay
        }
    }
}
