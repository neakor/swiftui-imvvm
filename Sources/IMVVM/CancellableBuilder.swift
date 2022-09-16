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

/// A result builder that allows a variadic number of `AnyCancellable` to be collected into an array.
@resultBuilder
public enum CancellableBuilder {
  public static func buildBlock(_ components: [AnyCancellable]...) -> [AnyCancellable] {
    components.reduce(into: [], +=)
  }

  public static func buildExpression(_ expression: Void) -> [AnyCancellable] {
    []
  }

  public static func buildExpression(_ expression: AnyCancellable) -> [AnyCancellable] {
    [expression]
  }

  /// Convert regular cancellables to AnyCancellable to dispose on deinit.
  public static func buildExpression(_ expression: any Cancellable) -> [AnyCancellable] {
    [AnyCancellable(expression.cancel)]
  }

  public static func buildExpression(_ expression: [AnyCancellable]) -> [AnyCancellable] {
    expression
  }

  public static func buildEither(first component: [AnyCancellable]) -> [AnyCancellable] {
    component
  }

  public static func buildEither(second component: [AnyCancellable]) -> [AnyCancellable] {
    component
  }

  public static func buildArray(_ components: [[AnyCancellable]]) -> [AnyCancellable] {
    components.reduce(into: [], +=)
  }

  public static func buildOptional(_ component: [AnyCancellable]?) -> [AnyCancellable] {
    if let component = component {
      return component
    } else {
      return []
    }
  }
}
