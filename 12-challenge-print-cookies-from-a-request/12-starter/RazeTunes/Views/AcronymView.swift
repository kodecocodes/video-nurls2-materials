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

// MARK: Acronym View
struct AcronymView: View {
  // MARK: Properties
  @State private var showAcronymSubmitSucceededAlert = false
  @State private var showAcronymSubmitFailedAlert = false

  private let acronym = Acronym(short: "COOL", long: "Code only on land")
  private let sender = AcronymSender()
  private let user = User(email: "jo@razeware.com", name: "jo", password: "password")

  // MARK: Body
  var body: some View {
    VStack {
      Image(systemName: "doc.text")
        .resizable()
        .frame(maxWidth: 90, maxHeight: 120)
        .padding(.bottom, 20)

      Button("Send Acronym") {
        Task {
          await sendAcronymTapped()
        }
      }
    }
    // swiftlint:disable all
    .alert("Successfully sent \(acronym.short) acronym",
           isPresented: $showAcronymSubmitSucceededAlert) {
      Button("Dismiss", role: .cancel) {
        showAcronymSubmitSucceededAlert = false
      }
    }
    .alert("Failed to send \(acronym.short) acronym",
          isPresented: $showAcronymSubmitFailedAlert) {
      Button("Dismiss", role: .cancel) {
        showAcronymSubmitFailedAlert = false
      }
    }
    // swiftlint:enable all
  }

  // MARK: Functions
  private func sendAcronymTapped() async {
    do {
      try await sender.send(acronym: acronym, for: user)

      Task { @MainActor in
        showAcronymSubmitSucceededAlert = true
      }
    } catch {
      Task { @MainActor in
        showAcronymSubmitFailedAlert = true
      }
    }
  }
}

// MARK: - Preview Provider
struct AcronymView_Previews: PreviewProvider {
  // MARK: Previews
  static var previews: some View {
    Group {
      AcronymView()
    }
  }
}
