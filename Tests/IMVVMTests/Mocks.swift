// MIT License
//
// Copyright (c) 2022 Yi Wang
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Combine
import Foundation
@testable import IMVVM

class MockInteractor: Interactor {
  private let _onLoad: () -> [AnyCancellable]
  private let _onViewAppear: () -> [AnyCancellable]

  init(onLoad: @escaping () -> [AnyCancellable] = { [] },
       onViewAppear: @escaping () -> [AnyCancellable] = { [] })
  {
    self._onLoad = onLoad
    self._onViewAppear = onViewAppear
  }

  var onLoadCallCount = 0
  override func onLoad() -> [AnyCancellable] {
    onLoadCallCount += 1
    return _onLoad()
  }

  var onViewAppearCallCount = 0
  override func onViewAppear() -> [AnyCancellable] {
    onViewAppearCallCount += 1
    return _onViewAppear()
  }

  var onViewDisappearCallCount = 0
  override func onViewDisappear() {
    onViewDisappearCallCount += 1
  }
}
