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

import Foundation
import SwiftUI

/// The observer of a SwiftUI view's lifecycle events.
///
/// This protocol should be used in conjunction with the `bind(observer:)` function of a `View`. This allows the
/// implementation of this protocol to receive the view's various lifecycle events to perform business logic accordingly.
public protocol ViewLifecycleObserver {
  /// Notify the observer when the bound `View` has appeared.
  func viewDidAppear()

  /// Notify the observer when the bound `View` has disappeared.
  func viewDidDisappear()
}

extension View {
  /// Bind the given lifecycle observer to this view.
  ///
  /// - Parameters:
  ///   - observer: The observer to be bound and receive this view's lifecycle events.
  /// - Returns: This view with the observer bound.
  public func bind<Observer: ViewLifecycleObserver>(observer: Observer) -> some View {
    onAppear {
      observer.viewDidAppear()
    }
    .onDisappear {
      observer.viewDidDisappear()
    }
  }

  /// Bind the given lifecycle observer to this view.
  ///
  /// - Parameters:
  ///   - observer: The observer to be bound and receive this view's lifecycle events.
  /// - Returns: The type erased version of thisview with the observer bound.
  public func bindTypeErased<Observer: ViewLifecycleObserver>(observer: Observer) -> TypeErasedView {
    onAppear {
      observer.viewDidAppear()
    }
    .onDisappear {
      observer.viewDidDisappear()
    }
    .typeErased()
  }
}
