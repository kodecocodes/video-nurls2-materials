/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

// MARK: Mutable Song Downloader
class MutableSongDownloader: NSObject, ObservableObject {
  // MARK: Song Download Error
  enum SongDownloadError: Error {
    case documentDirectoryError
    case failedToStoreSong
    case invalidResponse
  }

  // MARK: State
  enum State {
    case paused
    case downloading
    case failed
    case finished
    case waiting
  }

  // MARK: Static Properties
  static let BackgroundSongDownloadDidFinish =
  NSNotification.Name(rawValue: "BackgroundSongDownloadDidFinish")

  // MARK: Properties
  @Published var downloadLocation: URL?
  @Published var downloadProgress: Float = 0

  private var downloadURL: URL?
  private var downloadTask: URLSessionDownloadTask?
  private var resumeData: Data?
  // swiftlint:disable:next implicitly_unwrapped_optional
  private var session: URLSession!

  var state: State = .waiting

  // MARK: Initialization
  override init() {
    super.init()

    let identifier = "com.raywenderlich.razeTunes.mutableSongDownloader"
    let configuration = URLSessionConfiguration.background(withIdentifier: identifier)

    print("CREATING SESSION WITH IDENTIFIER")

    session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
  }

  // MARK: Functions
  func cancel() {
    state = .waiting

    downloadTask?.cancel()

    Task {
      await MainActor.run {
        downloadProgress = 0
      }
    }
  }

  func downloadSong(at url: URL) {
    downloadURL = url

    downloadTask = session.downloadTask(with: url)
    downloadTask?.resume()

    state = .downloading
  }

  func pause() {
    // swiftlint:disable:next trailing_closure
    downloadTask?.cancel(byProducingResumeData: { data in
      Task {
        await MainActor.run {
          self.resumeData = data

          self.state = .paused
        }
      }
    })
  }

  func resume() {
    guard let resumeData = resumeData else {
      return
    }

    downloadTask = session.downloadTask(withResumeData: resumeData)
    downloadTask?.resume()

    state = .downloading
  }
}

// MARK: - URLSession Download Delegate
extension MutableSongDownloader: URLSessionDownloadDelegate {
  // swiftlint:disable all
  func urlSession(_ session: URLSession,
                  downloadTask: URLSessionDownloadTask,
                  didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                  totalBytesExpectedToWrite: Int64) {
    Task {
      await MainActor.run {
        downloadProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)

        print("Progress: \(downloadProgress)")
      }
    }
  }

  func urlSession(_ session: URLSession,
                  downloadTask: URLSessionDownloadTask,
                  didFinishDownloadingTo location: URL) {
    // swiftlint:enable all
    let fileManager = FileManager.default

    guard let documentsPath = fileManager.urls(
      for: .documentDirectory,
      in: .userDomainMask).first
    else {
      Task {
        await MainActor.run {
          state = .failed
        }
      }

      return
    }

    let lastPathComponent = downloadURL?.lastPathComponent ?? "Song.m4a"
    let destinationURL = documentsPath.appendingPathComponent(lastPathComponent)

    do {
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }

      try fileManager.copyItem(at: location, to: destinationURL)

      Task {
        await MainActor.run {
          downloadLocation = destinationURL

          state = .finished
        }
      }
    } catch {
      Task {
        await MainActor.run {
          state = .failed
        }
      }
    }
  }

  // swiftlint:disable all
  func urlSession(_ session: URLSession,
                  task: URLSessionTask,
                  didCompleteWithError error: Error?) {
    // swiftline:enable all
    Task {
      await MainActor.run {
        if let httpResponse = task.response as? HTTPURLResponse,
        httpResponse.statusCode != 200 {
          state = .failed
        }
      }
    }
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    Task { @MainActor in
      print("urlSessionDidFinishEvents called.")

      NotificationCenter.default.post(name: Self.BackgroundSongDownloadDidFinish, object: nil)
    }
  }
}
