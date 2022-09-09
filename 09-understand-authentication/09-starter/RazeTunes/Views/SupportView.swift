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

// MARK: Support View
struct SupportView: View {
  // MARK: Properties
  @State private var chatMessage = ""
  @State private var messages: [String] = []
  // swiftlint:disable:next implicitly_unwrapped_optional
  @State private var webSocketTask: URLSessionWebSocketTask!

  // MARK: Body
  var body: some View {
    VStack {
      HStack {
        TextField("Enter a message", text: $chatMessage)
          .padding([.leading, .top, .bottom])

        Button("Send", action: sendMessageTapped)
          .padding(.trailing)
      }

      List(messages, id: \.self) { message in
        Text(message)
      }
      .onAppear(perform: setUpSocket)
      .onDisappear(perform: closeSocket)
    }
  }

  // MARK: Functions
  func closeSocket() {
    webSocketTask.cancel(with: .goingAway, reason: nil)

    messages = []
  }

  func listenForMessages() {
    webSocketTask.receive { result in
      switch result {
      case .failure(let error):
        print("Failed to receive message: \(error)")

      case .success(let message):
        switch message {
        case .string(let text):
          messages.insert(text, at: 0)

        case .data(let data):
          print("Received binary message: \(data)")

        @unknown default:
          fatalError("Listening for messages failed.")
        }

        listenForMessages()
      }
    }
  }

  func sendMessageTapped() {
    let message = URLSessionWebSocketTask.Message.string(self.chatMessage)

    webSocketTask.send(message) { error in
      if let error = error {
        print(error.localizedDescription)
      }
    }
  }

  func setUpSocket() {
    // swiftlint:disable:next force_unwrapping
    let webSocketURL = URL(string: "ws://localhost:8080/chat")!
    webSocketTask = URLSession.shared.webSocketTask(with: webSocketURL)

    listenForMessages()

    webSocketTask.resume()
  }
}

// MARK: - Preview Provider
struct SupportView_Previews: PreviewProvider {
  // MARK: Previews
  static var previews: some View {
    SupportView()
  }
}
