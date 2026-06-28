import Foundation
import os

private struct ServerAPIResponse: Decodable {
    let error: String?
}

class AceStreamEngine: Service {
    var accessToken: String?
    var playlist: String?
    var containerID: String?
    let token = UUID().uuidString

    override var maxWait: DispatchTimeInterval { DispatchTimeInterval.seconds(180) }
    override var checkEverySeconds: Double { 1.0 }
    override var defaultError: String { "Cannot run AceStream server." }

    override init() {
        _ = Process.runCommand(AppConstants.Podman.command, "kill", AppConstants.Podman.containerName)
        super.init()
    }

    override func run() {
        let process = Process.runCommand(
            AppConstants.Podman.command,
            "run",
            "--rm",
            "--detach",
            "--platform=\(AppConstants.Podman.platform)",
            "--publish=\(AppConstants.Podman.enginePort):\(AppConstants.Podman.enginePort)",
            "--publish=\(AppConstants.Podman.proxyPort):\(AppConstants.Podman.proxyPort)",
            "--name=\(AppConstants.Podman.containerName)",
            AppConstants.Podman.image,
            "--client-console",
            "--access-token=\(token)",
            "--allow-user-config",
            "--bind-all",
            "--live-buffer-time=15",
            "--live-cache-type=memory",
            "--vod-buffer=15",
            "--vod-cache-type=memory"
        )
        if process.standardOutContents.isEmpty {
            os_log("Cannot get engine ID...")
            callback(nil)
            return
        }
        containerID = process.standardOutContents
    }

    override func check() {
        if let accessToken = accessToken, containerID != nil {
            checkServerAPI(accessToken)
            return
        }

        let serverURL = AppConstants.Podman.baseURL
            .appendingPathComponent("/webui/app/\(token)/server")
        os_log("Check server up at %{public}@ …", serverURL.absoluteString)
        urlSession.dataTask(with: serverURL) { data, _, _ in
            if let data = data, let str = String(data: data, encoding: .utf8) {
                self.accessToken = str.matches(for: "\"access_token\": \"([^\"]{64})\"").first
                self.playlist = str.matches(for: "\"playlist_id\": \"([^\"]{7})\"").first
                if self.containerID != nil, self.accessToken != nil {
                    self.check()
                    return
                }
            }
            self.scheduleCheck()
        }.resume()
    }

    private func checkServerAPI(_ accessToken: String) {
        let url = AppConstants.Podman.baseURL.appendingPathComponent("/server/api")
            .appendingQuery("method", "playlist_get")
            .appendingQuery("token", accessToken)
        os_log("Check server API up at %{public}@ …", url.absoluteString.scrubHashes())

        urlSession.jsonDataTask(with: url, decodable: ServerAPIResponse.self) { data in
            if let data = data, data.error == nil {
                self.callbackInMainThread()
                return
            }
            self.scheduleCheck()
        }.resume()
    }
}
