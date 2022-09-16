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

/// TypeErasedView is a drop in replacement for SwiftUI's `AnyView`.
///
/// `AnyView` has two major issues that the `TypeErasedView` solves:
///   1. A view hierarchy containing many `AnyView` can have rendering performance issues.
///   2. Wrapping an `AnyView` within another `AnyView` can erase certain modifiers such as `onAppear` and
///   `onDisappear`. This is quite error-prone as different portions of the codebase can unintentionally cause more
///   than one wrapping.
///
///  Using a TypeErasedView enables many architectural benefits:
///   1. Each feature can be written in its own package without exposing the individual classes as `public`. A single
///   `public` factory can be used to return a TypeErasedView to the parent view package for presentation.
///   2. A parent feature containing many child views does not need to be modified when new child views are added or
///   modified, when the child views are constructed as plugins.
///   3. A view/feature's lifecycle can be managed by storing and releasing the TypeErasedView reference.
public struct TypeErasedView: View {
  // swiftlint:disable:next no_any_view
  private let content: AnyView

  public init<Content: View>(_ content: Content) {
    // swiftlint:disable:next no_any_view
    self.content = AnyView(content)
  }

  public init(_ alreadyErased: TypeErasedView) {
    self.content = alreadyErased.content
  }

  // swiftlint:disable:next no_any_view
  public init(_ anyView: AnyView) {
    self.content = anyView
  }

  public var body: some View {
    content
  }
}

extension View {
  /// Type erase this view.
  ///
  /// - Returns: The type erased view.
  public func typeErased() -> TypeErasedView {
    TypeErasedView(self)
  }
}
