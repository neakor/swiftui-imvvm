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

extension Task: Cancellable {}

extension Task {
  public var anyCancellable: AnyCancellable {
    AnyCancellable(cancel)
  }
}

extension Task {
  /// When the interactor deinits, the task is cancelled.
  ///
  /// This function provides the utility to manage Task lifecycle inside a `Interactor` implementation. For
  /// example:
  ///
  ///     class MyInteractor: Interactor {
  ///       func buttonDidTap() {
  ///         Task {
  ///           ...
  ///         }
  ///         .cancelOnDeinit(of: self)
  ///       }
  ///     }
  ///
  /// - Note: Because this function causes the given interactor to stongly retain the task, this means the task
  /// itself should not strongly retain the interactor. Otherwise a retain cycle would occur causing memory leaks.
  ///
  /// This function is thread-safe. Invocations of this function to the same interactor instance can be performed on
  /// the different threads.
  ///
  /// This function can only be invoked after the given interactor has loaded. This is done via the interactor's
  /// `viewDidAppear` function. Generally speaking, this interactor should be bound to the lifecycle of a `View`.
  /// See `ViewLifecycleObserver` for more details.
  ///
  /// - Parameters:
  ///   - interactor: The interactor to bind the task's lifecycle to.
  public func cancelOnDeinit<InteractorType: Interactor>(of interactor: InteractorType) {
    if !interactor.isLoaded {
      fatalError("\(interactor) has not been loaded")
    }
    interactor.deinitCancelBag.store(AnyCancellable(self))
  }

  /// When the interactor's view disappears, the task is cancelled.
  ///
  /// This function provides the utility to manage Task lifecycle inside a `Interactor` implementation. For
  /// example:
  ///
  ///     class MyInteractor: Interactor {
  ///       func buttonDidTap() {
  ///         Task {
  ///           ...
  ///         }
  ///         .cancelOnViewDidDisappear(of: self)
  ///       }
  ///     }
  ///
  /// - Note: Because this function causes the given interactor to stongly retain the task, this means the task
  /// itself should not strongly retain the interactor. Otherwise a retain cycle would occur causing memory leaks.
  ///
  /// This function is thread-safe. Invocations of this function to the same interactor instance can be performed on
  /// the different threads.
  ///
  /// This function can only be invoked after the given interactor has received notification that its view has
  /// appeared. This is done via the interactor's `viewDidAppear` function. Generally speaking, this interactor
  /// should be bound to the lifecycle of a `View`. See `ViewLifecycleObserver` for more details.
  ///
  /// - Parameters:
  ///   - interactor: The interactor to bind the task's lifecycle to.
  public func cancelOnViewDidDisappear<InteractorType: Interactor>(of interactor: InteractorType) {
    if !interactor.hasViewAppeared {
      fatalError("\(interactor)'s view has not appeared")
    }
    interactor.viewAppearanceCancelBag.store(AnyCancellable(self))
  }
}
