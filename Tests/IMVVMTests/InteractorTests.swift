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

class InteractorTests: XCTestCase {
  func test_viewLifecycleEvents() {
    weak var interactorWeakRef: MockInteractor?
    var onLoadCancellableCallCount = 0
    var onViewAppearCancellableCallCount = 0

    autoreleasepool {
      let onLoadCancellable = AnyCancellable {
        onLoadCancellableCallCount += 1
      }

      let interactor = MockInteractor(onLoad: { [onLoadCancellable] })
      interactorWeakRef = interactor

      XCTAssertNotNil(interactorWeakRef)

      XCTAssertEqual(interactor.onLoadCallCount, 0)
      XCTAssertEqual(interactor.onViewAppearCallCount, 0)
      XCTAssertEqual(interactor.onViewDisappearCallCount, 0)
      XCTAssertEqual(onLoadCancellableCallCount, 0)
      XCTAssertEqual(onViewAppearCancellableCallCount, 0)
      XCTAssertTrue(interactor.deinitCancelBag.isEmpty())
      XCTAssertTrue(interactor.viewAppearanceCancelBag.isEmpty())

      interactor.viewDidAppear()

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
      XCTAssertEqual(interactor.onViewAppearCallCount, 1)
      XCTAssertEqual(interactor.onViewDisappearCallCount, 0)
      XCTAssertEqual(onLoadCancellableCallCount, 0)
      XCTAssertEqual(onViewAppearCancellableCallCount, 0)
      XCTAssertTrue(interactor.deinitCancelBag.contains(onLoadCancellable))
      XCTAssertFalse(interactor.viewAppearanceCancelBag.isEmpty())

      subject.send(1)

      XCTAssertTrue(didReceiveValue)

      interactor.viewDidDisappear()

      XCTAssertEqual(interactor.onLoadCallCount, 1)
      XCTAssertEqual(interactor.onViewAppearCallCount, 1)
      XCTAssertEqual(interactor.onViewDisappearCallCount, 1)
      XCTAssertEqual(onLoadCancellableCallCount, 0)
      XCTAssertEqual(onViewAppearCancellableCallCount, 1)
      XCTAssertTrue(interactor.deinitCancelBag.contains(onLoadCancellable))
      XCTAssertTrue(interactor.viewAppearanceCancelBag.isEmpty())
    }

    XCTAssertEqual(onLoadCancellableCallCount, 1)
    XCTAssertEqual(onViewAppearCancellableCallCount, 1)
    XCTAssertNil(interactorWeakRef)
  }

  func test_sink_cancelOnDeinit_removeBoundCancellable() {
    let interactor = MockInteractor()
    interactor.viewDidAppear()

    XCTAssertTrue(interactor.deinitCancelBag.isEmpty())

    let subject = PassthroughSubject<Int, Never>()
    subject
      .ignoreOutput()
      .sink(receiveValue: { _ in })
      .cancelOnDeinit(of: interactor)

    XCTAssertFalse(interactor.deinitCancelBag.isEmpty())

    subject.send(1)

    XCTAssertFalse(interactor.deinitCancelBag.isEmpty())
  }

  func test_sink_cancelOnDeinit_subscriptionRetainInteractor_NoRetainInteractor() {
    weak var interactorWeakRef: MockInteractor?

    autoreleasepool {
      let interactor = MockInteractor()
      interactor.viewDidAppear()
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
    let interactor = MockInteractor()

    XCTAssertEqual(interactor.onLoadCallCount, 0)
    XCTAssertFalse(interactor.isLoaded)

    interactor.viewDidAppear()

    XCTAssertEqual(interactor.onLoadCallCount, 1)
    XCTAssertTrue(interactor.isLoaded)

    interactor.viewDidDisappear()

    XCTAssertEqual(interactor.onLoadCallCount, 1)
    XCTAssertTrue(interactor.isLoaded)
  }

  func test_sink_cancelOnDisappear_removeBoundCancellable() {
    let interactor = MockInteractor()
    interactor.viewDidAppear()

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

  func test_sink_cancelOnDisappear_subscriptionRetainInteractor_NoRetainInteractor() {
    weak var interactorWeakRef: MockInteractor?

    autoreleasepool {
      let interactor = MockInteractor()
      interactor.viewDidAppear()
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
