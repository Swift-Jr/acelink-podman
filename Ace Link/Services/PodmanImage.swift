import Foundation

class PodmanImage: Service {
    override var maxWait: DispatchTimeInterval { DispatchTimeInterval.seconds(5) }
    override var checkEverySeconds: Double { 1.0 }
    override var defaultError: String {
        "Cannot find \(AppConstants.Podman.image). Run `make podman` before launching streams."
    }

    override func hasRunSuccesfully() -> Bool {
        let process = Process.runCommand(
            AppConstants.Podman.command,
            "image",
            "inspect",
            "--format=OK",
            AppConstants.Podman.image
        )
        return process.terminationStatus == 0
    }
}
