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

/// An `Interactor` that has an associated view model used to transform the data from this interactor to presentation
/// data for the corresponding view to display.
///
/// - Important: Please see `Interactor` documentation for binding requirements.
open class ViewModelInteractor<ViewModelType: ViewModel>: Interactor {
  /// Override this function to setup the subscriptions this interactor requires on start.
  ///
  /// All the created subscriptions returned from this function are bound to the deinit lifecycle of this interactor.
  ///
  ///     class MyInteractor: Interactor {
  ///       @CancellableBuilder
  ///       override func onLoad(viewModel: MyViewModel) -> [AnyCancellable] {
  ///         myDataStream
  ///           .sink {...}
  ///
  ///         mySecondDataStream
  ///           .sink {...}
  ///       }
  ///     }
  ///
  /// - Parameters:
  ///   - viewModel: The view model used to transform and provide presentation data for the corresponding view to
  ///   display.
  /// - Returns: An array of subscription `AnyCancellable`.
  @CancellableBuilder
  open func onLoad(viewModel: ViewModelType) -> [AnyCancellable] {}

  /// Override this function to perform logic or setup the subscriptions when the view has appeared.
  ///
  /// All the created subscriptions returned from this function are bound to the disappearance of this interactor's
  /// corresponding view.
  ///
  ///     class MyInteractor: Interactor {
  ///       @CancellableBuilder
  ///       override func onViewAppear(viewModel: MyViewModel) -> [AnyCancellable] {
  ///         myDataStream
  ///           .sink {...}
  ///
  ///         mySecondDataStream
  ///           .sink {...}
  ///       }
  ///     }
  ///
  /// - Parameters:
  ///   - viewModel: The view model used to transform and provide presentation data for the corresponding view to
  ///   display.
  /// - Returns: An array of subscription `AnyCancellable`.
  @CancellableBuilder
  open func onViewAppear(viewModel: ViewModelType) -> [AnyCancellable] {}

  /// Override this function to perform logic when the interactor's view disappears.
  ///
  /// - Parameters:
  ///   - viewModel: The view model used to transform and provide presentation data for the corresponding view to
  ///   display.
  open func onViewDisappear(viewModel: ViewModelType) {}
}

// MARK: - ViewWithModelLifecycleObserver Conformance

extension ViewModelInteractor: ViewWithModelLifecycleObserver {
  public final func viewDidAppear(viewModel: ViewModelType) {
    let occurrence = processViewDidAppear()
    guard occurrence != .invalid else {
      return
    }

    if occurrence == .firstTime {
      deinitCancelBag.store(onLoad(viewModel: viewModel))
    }

    viewAppearanceCancelBag.store(onViewAppear(viewModel: viewModel))
  }

  public final func viewDidDisappear(viewModel: ViewModelType) {
    let occurrence = processViewDidDisappear()
    guard occurrence != .invalid else {
      return
    }

    onViewDisappear(viewModel: viewModel)
  }
}
