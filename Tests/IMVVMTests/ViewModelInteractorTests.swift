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
import XCTest

class ViewModelInteractorTests: XCTestCase {
  func test_viewLifecycleEvents() {
    weak var interactorWeakRef: MockViewModelInteractor?
    var onLoadCancellableCallCount = 0
    var onLoadViewModelCancellableCallCount = 0
    var onViewAppearCancellableCallCount = 0

    autoreleasepool {
      let onLoadCancellable = AnyCancellable {
        onLoadCancellableCallCount += 1
      }
      let onLoadViewModelCancellable = AnyCancellable {
        onLoadViewModelCancellableCallCount += 1
      }

      let interactor = MockViewModelInteractor(
        onLoad: {
          [onLoadCancellable]
        },
        onLoadViewModel: { viewModel in
          XCTAssertNotNil(viewModel)
          return [onLoadViewModelCancellable]
        }
      )
      interactorWeakRef = interactor
      let viewModel = MockViewModel()

      XCTAssertNotNil(interactorWeakRef)

      XCTAssertEqual(interactor.onLoadCallCount, 0)
      XCTAssertEqual(interactor.onLoadViewModelCallCount, 0)
      XCTAssertEqual(interactor.onViewAppearCallCount, 0)
      XCTAssertEqual(interactor.onViewAppearViewModelCallCount, 0)
      XCTAssertEqual(interactor.onViewDisappearCallCount, 0)
      XCTAssertEqual(interactor.onViewDisappearViewModelCallCount, 0)
      XCTAssertEqual(onLoadCancellableCallCount, 0)
      XCTAssertEqual(onLoadViewModelCancellableCallCount, 0)
      XCTAssertEqual(onViewAppearCancellableCallCount, 0)
      XCTAssertTrue(interactor.deinitCancelBag.isEmpty())
      XCTAssertTrue(interactor.viewAppearanceCancelBag.isEmpty())

      interactor.viewDidAppear(viewModel: viewModel)

      var didReceiveValue = false
      let subject = PassthroughSubject<Int, Never>()
      subject
        .handleEvents(receiveCancel: {
          onViewAppearCancellableCallCount += 1
        })
        .sink { _ in
          didReceiveValue = true
          // Strongly retain interactor here creating a retain cycle of:
          // interactor->cancelBag->cancellable->subscription->interactor.
          XCTAssertNotNil(interactor)
        }
        .cancelOnViewDidDisappear(of: interactor)

      XCTAssertEqual(interactor.onLoadCallCount, 1)
      XCTAssertEqual(interactor.onLoadViewModelCallCount, 1)
      XCTAssertEqual(interactor.onViewAppearCallCount, 1)
      XCTAssertEqual(interactor.onViewAppearViewModelCallCount, 1)
      XCTAssertEqual(interactor.onViewDisappearCallCount, 0)
      XCTAssertEqual(interactor.onViewDisappearViewModelCallCount, 0)
      XCTAssertEqual(onLoadCancellableCallCount, 0)
      XCTAssertEqual(onLoadViewModelCancellableCallCount, 0)
      XCTAssertEqual(onViewAppearCancellableCallCount, 0)
      XCTAssertTrue(interactor.deinitCancelBag.contains(onLoadCancellable))
      XCTAssertTrue(interactor.deinitCancelBag.contains(onLoadViewModelCancellable))
      XCTAssertFalse(interactor.viewAppearanceCancelBag.isEmpty())

      subject.send(1)

      XCTAssertTrue(didReceiveValue)

      interactor.viewDidDisappear(viewModel: viewModel)

      XCTAssertEqual(interactor.onLoadCallCount, 1)
      XCTAssertEqual(interactor.onLoadViewModelCallCount, 1)
      XCTAssertEqual(interactor.onViewAppearCallCount, 1)
      XCTAssertEqual(interactor.onViewAppearViewModelCallCount, 1)
      XCTAssertEqual(interactor.onViewDisappearCallCount, 1)
      XCTAssertEqual(interactor.onViewDisappearViewModelCallCount, 1)
      XCTAssertEqual(onLoadCancellableCallCount, 0)
      XCTAssertEqual(onLoadViewModelCancellableCallCount, 0)
      XCTAssertEqual(onViewAppearCancellableCallCount, 1)
      XCTAssertTrue(interactor.deinitCancelBag.contains(onLoadCancellable))
      XCTAssertTrue(interactor.viewAppearanceCancelBag.isEmpty())
    }

    XCTAssertEqual(onLoadCancellableCallCount, 1)
    XCTAssertEqual(onLoadViewModelCancellableCallCount, 1)
    XCTAssertEqual(onViewAppearCancellableCallCount, 1)
    XCTAssertNil(interactorWeakRef)
  }

  func test_sinkWithAutoCancelOnDeinit_removeBoundCancellable() {
    let interactor = MockViewModelInteractor()
    interactor.viewDidAppear(viewModel: MockViewModel())

    XCTAssertTrue(interactor.deinitCancelBag.isEmpty())

    let subject = PassthroughSubject<Int, Never>()
    subject
      .ignoreOutput()
      .sink(receiveValue: { _ in })
      .cancelOnDeinit(of: interactor)

    XCTAssertFalse(interactor.deinitCancelBag.isEmpty())

    subject.send(1)

    XCTAssertFalse(interactor.deinitCancelBag.isEmpty())

    subject.send(completion: .finished)
  }

  func test_sinkWithAutoCancelOnDeinit_subscriptionRetainInteractor_NoRetainInteractor() {
    weak var interactorWeakRef: MockViewModelInteractor?

    autoreleasepool {
      let interactor = MockViewModelInteractor()
      interactor.viewDidAppear(viewModel: MockViewModel())
      interactorWeakRef = interactor

      XCTAssertNotNil(interactorWeakRef)

      var didReceiveValue = false
      let subject = PassthroughSubject<Int, Never>()
      subject
        .sink { _ in
          didReceiveValue = true
          // Strongly retain interactor here creating a retain cycle of:
          // interactor->cancelBag->cancellable->subscription->interactor.
          XCTAssertNotNil(interactor)
        }
        .cancelOnDeinit(of: interactor)

      subject.send(1)
      // Completion event should break the retain cycle by removing the strong retain between cancelBag to cancellable.
      subject.send(completion: .finished)

      XCTAssertTrue(didReceiveValue)
    }

    XCTAssertNil(interactorWeakRef)
  }

  func test_activate_shouldCallDidBecomeActive() {
    let interactor = MockViewModelInteractor()

    XCTAssertEqual(interactor.onLoadCallCount, 0)
    XCTAssertFalse(interactor.isLoaded)

    interactor.viewDidAppear(viewModel: MockViewModel())

    XCTAssertEqual(interactor.onLoadCallCount, 1)
    XCTAssertTrue(interactor.isLoaded)

    interactor.viewDidDisappear(viewModel: MockViewModel())

    XCTAssertEqual(interactor.onLoadCallCount, 1)
    XCTAssertTrue(interactor.isLoaded)
  }

  func test_sinkWithAutoCancelOnDisappear_removeBoundCancellable() {
    let interactor = MockViewModelInteractor()
    interactor.viewDidAppear(viewModel: MockViewModel())

    XCTAssertTrue(interactor.deinitCancelBag.isEmpty())

    let subject = PassthroughSubject<Int, Never>()
    subject
      .ignoreOutput()
      .sink(receiveValue: { _ in })
      .cancelOnViewDidDisappear(of: interactor)

    XCTAssertFalse(interactor.viewAppearanceCancelBag.isEmpty())

    subject.send(1)

    XCTAssertFalse(interactor.viewAppearanceCancelBag.isEmpty())

    subject.send(completion: .finished)

    XCTAssertTrue(interactor.deinitCancelBag.isEmpty())
  }

  func test_sinkWithAutoCancelOnDisappear_subscriptionRetainInteractor_NoRetainInteractor() {
    weak var interactorWeakRef: MockViewModelInteractor?

    autoreleasepool {
      let interactor = MockViewModelInteractor()
      interactor.viewDidAppear(viewModel: MockViewModel())
      interactorWeakRef = interactor

      XCTAssertNotNil(interactorWeakRef)

      var didReceiveValue = false
      let subject = PassthroughSubject<Int, Never>()
      subject
        .sink { _ in
          didReceiveValue = true
          // Strongly retain interactor here creating a retain cycle of:
          // interactor->cancelBag->cancellable->subscription->interactor.
          XCTAssertNotNil(interactor)
        }
        .cancelOnViewDidDisappear(of: interactor)

      subject.send(1)
      // Completion event should break the retain cycle by removing the strong retain between cancelBag to cancellable.
      subject.send(completion: .finished)

      XCTAssertTrue(didReceiveValue)
    }

    XCTAssertNil(interactorWeakRef)
  }
}
