import Foundation

public enum AppConstants {
    static let displayName = "Ace Link Podman"
    static let supportDirectoryName = "acelink-podman"

    static var version: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "0.0.0"
    }

    enum Scheme: String, CaseIterable {
        case magnet
        case acestream
    }

    enum StreamType {
        case acestream
        case magnet
        case none
    }

    enum Podman {
        static let baseURL = URL(string: "http://127.0.0.1:\(enginePort)")!
        static let command = "podman"
        static let containerName = "acelink-podman--ace-stream-server"
        static let enginePort = 6878
        static let image = "localhost/swift-jr/acelink-podman:\(AppConstants.version)"
        static let platform = "linux/amd64"
        static let proxyPort = 6888
    }
}
