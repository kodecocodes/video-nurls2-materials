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

// MARK: Rating Uploader
class RatingUploader: ObservableObject {
  // MARK: Rating Upload Error
  enum RatingUploadError: Error {
    case failedToCreateUploadData
    case failedToCreateUploadURL
    case invalidResponse
  }

  // MARK: Properties
  private let session: URLSession
  private let sessionConfiguration: URLSessionConfiguration

  // MARK: Initialization
  init() {
    self.sessionConfiguration = URLSessionConfiguration.default
    self.session = URLSession(configuration: sessionConfiguration)
  }

  // MARK: Functions
  func submit(rating: Int, for musicItem: MusicItem) async throws {
    guard let uploadURL = URL(string: "http://localhost:8080/upload") else {
      throw RatingUploadError.failedToCreateUploadURL
    }

    var request = URLRequest(url: uploadURL)
    request.httpMethod = "Post"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let json = """
    {
      "id": \(musicItem.id),
      "artistName": "\(musicItem.artistName)",
      "trackName": "\(musicItem.trackName)",
      "rating": \(rating)
    }
    """

    guard let uploadData = json.data(using: .utf8) else {
      throw RatingUploadError.failedToCreateUploadData
    }

    let (_, response) = try await session.upload(for: request, from: uploadData)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw RatingUploadError.invalidResponse
    }
  }
}
