import Foundation
import os

private struct GetPlaylistResponse: Decodable {
    let result: Result

    struct Result: Decodable {
        let playlist: [Playlist]
    }

    struct Playlist: Decodable {
        let title: String
    }
}

private struct AddPlaylistResponse: Decodable {
    let result: Int?
    let error: String?
}

class AceStreamPlaylist: Service {
    let aceStreamEngine: AceStreamEngine
    let stream: StreamFile
    var title: String?
    private var addPlaylistCompleted = false
    private var addPlaylistFailed = false
    private var addPlaylistCompletedAt: DispatchTime?
    private var fallbackTitle: String { "\(AppConstants.displayName) - \(stream.hash.prefix(7))" }

    override var maxWait: DispatchTimeInterval { DispatchTimeInterval.seconds(60) }
    override var checkEverySeconds: Double { 1.0 }
    override var defaultError: String { "Cannot get stream title." }

    init(aceStreamEngine: AceStreamEngine, stream: StreamFile) {
        self.aceStreamEngine = aceStreamEngine
        self.stream = stream

        super.init()

        os_log("Getting stream title for %s=%s…", stream.param, stream.hash)
    }

    override func run() {
        let url = AppConstants.Podman.baseURL.appendingPathComponent("/server/api")
            .appendingQuery("method", "playlist_add_item")
            .appendingQuery("token", aceStreamEngine.accessToken!)
            .appendingQuery(stream.param, stream.hash)
            .appendingQuery("title", fallbackTitle)
            .appendingQuery("category", "other")
            .appendingQuery("subcategory", "")
            .appendingQuery("auto_search", "0")

        urlSession.jsonDataTask(with: url, decodable: AddPlaylistResponse.self) { data in
            self.addPlaylistCompleted = true
            self.addPlaylistCompletedAt = DispatchTime.now()
            if let data = data, data.result != nil, data.error == nil {
                return
            }

            self.addPlaylistFailed = true
            if let error = data?.error {
                os_log("Cannot add stream to playlist: %{public}@", error)
            } else {
                os_log("Cannot add stream to playlist.")
            }
        }.resume()
    }

    override func check() {
        guard addPlaylistCompleted else {
            scheduleCheck()
            return
        }

        let url = AppConstants.Podman.baseURL.appendingPathComponent("/server/api")
            .appendingQuery("method", "playlist_get")
            .appendingQuery("token", aceStreamEngine.accessToken!)

        urlSession.jsonDataTask(with: url, decodable: GetPlaylistResponse.self) { data in
            if let playlist = data?.result.playlist.first {
                os_log("Got title: %s", playlist.title)
                self.title = playlist.title
                self.callbackInMainThread()
                return
            }
            if self.addPlaylistCompleted, self.addPlaylistFailed {
                os_log("Using fallback title: %s", self.fallbackTitle)
                self.title = self.fallbackTitle
                self.callbackInMainThread()
                return
            }
            if let completedAt = self.addPlaylistCompletedAt,
               DispatchTime.now() >= completedAt + DispatchTimeInterval.seconds(5) {
                os_log("Timed out waiting for playlist title, using fallback title: %s", self.fallbackTitle)
                self.title = self.fallbackTitle
                self.callbackInMainThread()
                return
            }
            self.scheduleCheck()
        }.resume()
    }
}
