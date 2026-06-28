import Foundation

class PodmanEngine: Service {
    override var maxWait: DispatchTimeInterval { DispatchTimeInterval.seconds(180) }
    override var checkEverySeconds: Double { 2.0 }
    override var defaultError: String { "Cannot start Podman engine." }

    override func run() {
        _ = Process.runCommand(AppConstants.Podman.command, "machine", "start")
    }

    override func hasRunSuccesfully() -> Bool {
        let process = Process.runCommand(AppConstants.Podman.command, "ps")
        return process.terminationStatus == 0
    }
}
