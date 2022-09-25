//
// Copyright (c) 2022. City Storage Systems LLC
//

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
