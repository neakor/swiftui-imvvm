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

class MockViewModel: ViewModel {}

class MockViewModelInteractor: ViewModelInteractor<MockViewModel> {
  private let _onLoad: () -> [AnyCancellable]
  private let _onLoadViewModel: (MockViewModel) -> [AnyCancellable]
  private let _onViewAppear: () -> [AnyCancellable]
  private let _onViewAppearViewModel: (MockViewModel) -> [AnyCancellable]

  init(
    onLoad: @escaping () -> [AnyCancellable] = { [] },
    onLoadViewModel: @escaping (MockViewModel) -> [AnyCancellable] = { _ in [] },
    onViewAppear: @escaping () -> [AnyCancellable] = { [] },
    onViewAppearViewModel: @escaping (MockViewModel) -> [AnyCancellable] = { _ in [] }
  ) {
    self._onLoad = onLoad
    self._onLoadViewModel = onLoadViewModel
    self._onViewAppear = onViewAppear
    self._onViewAppearViewModel = onViewAppearViewModel
  }

  var onLoadCallCount = 0
  override func onLoad() -> [AnyCancellable] {
    onLoadCallCount += 1
    return _onLoad()
  }

  var onLoadViewModelCallCount = 0
  override func onLoad(viewModel: MockViewModel) -> [AnyCancellable] {
    onLoadViewModelCallCount += 1
    return _onLoadViewModel(viewModel)
  }

  var onViewAppearCallCount = 0
  override func onViewAppear() -> [AnyCancellable] {
    onViewAppearCallCount += 1
    return _onViewAppear()
  }

  var onViewAppearViewModelCallCount = 0
  override func onViewAppear(viewModel: MockViewModel) -> [AnyCancellable] {
    onViewAppearViewModelCallCount += 1
    return _onViewAppearViewModel(viewModel)
  }

  var onViewDisappearCallCount = 0
  override func onViewDisappear() {
    onViewDisappearCallCount += 1
  }

  var onViewDisappearViewModelCallCount = 0
  override func onViewDisappear(viewModel: MockViewModel) {
    onViewDisappearViewModelCallCount += 1
  }
}
