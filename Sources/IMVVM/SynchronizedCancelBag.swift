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

/// A collection providing thread-safe access to a set of cancellables.
///
/// All the stored cancellabels are cancelled when this instance deinits.
public class SynchronizedCancelBag {
  private var cancellables: [ObjectIdentifier: Cancellable] = [:]
  private let cancellablesLock = NSRecursiveLock()

  public init() {}

  /// Store the given cancellable.
  ///
  /// - Parameters:
  ///    - cancellable: The cancellable to store.
  public func store(_ cancellable: AnyCancellable) {
    cancellablesLock.lock()
    defer {
      cancellablesLock.unlock()
    }

    cancellables[cancellable.id] = cancellable
  }

  /// Store the given cancellables.
  ///
  /// - Parameters:
  ///    - cancellables: The cancellables to store.
  public func store<S: Sequence>(_ sequence: S) where S.Element == AnyCancellable {
    cancellablesLock.lock()
    defer {
      cancellablesLock.unlock()
    }

    for cancellable in sequence {
      cancellables[cancellable.id] = cancellable
    }
  }

  public func cancelAll() {
    cancellablesLock.lock()
    defer {
      cancellablesLock.unlock()
    }

    for cancellable in cancellables.values {
      cancellable.cancel()
    }
    cancellables.removeAll()
  }

  public func remove<C: Identifiable>(_ cancellable: C) where C.ID == ObjectIdentifier {
    cancellablesLock.lock()
    defer {
      cancellablesLock.unlock()
    }

    cancellables[cancellable.id] = nil
  }

  public func contains<C: Identifiable>(_ cancellable: C) -> Bool where C.ID == ObjectIdentifier {
    cancellablesLock.lock()
    defer {
      cancellablesLock.unlock()
    }

    return cancellables[cancellable.id] != nil
  }

  public func isEmpty() -> Bool {
    cancellablesLock.lock()
    defer {
      cancellablesLock.unlock()
    }

    return cancellables.isEmpty
  }
}

extension AnyCancellable: Identifiable {
  public func store(in bag: inout SynchronizedCancelBag) {
    bag.store(self)
  }
}
