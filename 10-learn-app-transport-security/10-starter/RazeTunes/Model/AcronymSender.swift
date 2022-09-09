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

import Foundation

// MARK: Acronym Sender
class AcronymSender {
  // MARK: Acronym Error
  enum AcronymError: Error {
    case failedToDecodeAuthToken
    case failedToEncodeAcronym
    case failedToEncodeUserCredentials
    case invalidAcronymResponse
    case invalidLoginResponse
  }

  // MARK: Properties
  private let session: URLSession
  private let sessionConfiguration: URLSessionConfiguration

  private let baseURL: URL
  private let loginEndpoint: URL
  private let newEndpoint: URL
  private let newUserEndpoint: URL

  // MARK: Initialization
  init() {
    self.sessionConfiguration = URLSessionConfiguration.default
    self.sessionConfiguration.waitsForConnectivity = true
    self.session = URLSession(configuration: sessionConfiguration)

    // swiftlint:disable force_unwrapping
    self.baseURL = URL(string: "https://tilftw.herokuapp.com/")!
    self.loginEndpoint = URL(string: "login", relativeTo: baseURL)!
    self.newEndpoint = URL(string: "new", relativeTo: baseURL)!
    self.newUserEndpoint = URL(string: "users", relativeTo: baseURL)!
    // swiftlint:enable force_unwrapping
  }

  // MARK: Functions
  func send(acronym: Acronym, for user: User) async throws {
    let credentials = "\(user.email):\(user.password)"

    guard let data = credentials.data(using: .utf8) else {
      throw AcronymError.failedToEncodeUserCredentials
    }

    let encodedString = data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))

    var loginRequest = URLRequest(url: loginEndpoint)
    loginRequest.httpMethod = "POST"
    loginRequest.allHTTPHeaderFields = [
      "accept": "application/json",
      "content-type": "application/json",
      "authorization": "Basic \(encodedString)"
    ]

    let (loginData, loginResponse) = try await session.data(for: loginRequest)

    guard let httpLoginResponse = loginResponse as? HTTPURLResponse,
      httpLoginResponse.statusCode == 200
    else {
      throw AcronymError.invalidLoginResponse
    }

    var auth = Auth(token: "")

    do {
      auth = try JSONDecoder().decode(Auth.self, from: loginData)
    } catch {
      throw AcronymError.failedToDecodeAuthToken
    }

    var acronymRequest = URLRequest(url: newEndpoint)
    acronymRequest.httpMethod = "POST"
    acronymRequest.allHTTPHeaderFields = [
      "accept": "application/json",
      "content-type": "application/json",
      "authorization": "Bearer \(auth.token)"
    ]

    do {
      acronymRequest.httpBody = try JSONEncoder().encode(acronym)
    } catch {
      throw AcronymError.failedToEncodeAcronym
    }

    let (_, acronymResponse) = try await session.data(for: acronymRequest)

    guard let httpAcronymResponse = acronymResponse as? HTTPURLResponse,
      httpAcronymResponse.statusCode == 200
    else {
      throw AcronymError.invalidAcronymResponse
    }
  }
}
