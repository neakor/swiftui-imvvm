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

/// The base class of an object providing data to a view's interactor and functionality to handle user events such as
/// button taps.
///
/// An interactor is a helper object in the MVVM pattern that contains the application business logic. It should
/// perform network operations that supply data to a `ViewModel` for display. It also provides functionality to the
/// view to handle user events such as button taps. Because of this relationship, the view generally holds a strong
/// reference to the interactor to handle user interactions. The interactor holds a strong reference to the view model
/// to send network data for display.
///
/// The `Interactor` base implementation provides utility functions that help manage business logic, such as handling
/// subscription cancellables. Subclasses should override the lifecycle functions such as `onLoad` and `onViewAppear`
/// to setup all the necessary subscriptions.
///
/// - Important: An `interactor` is a `ViewLifecycleObserver`. It should be bound to the associated
/// view via the view's `bind(observer:)` modifier, inside the view implementation. This allows the interactor to
/// activate its lifecycle functions.
///
///     struct MyView: View {
///       @StateObject var interactor: MyInteractor
///
///       body: some View {
///         myContent
///           .bind(observer: interactor)
///       }
///     }
///
/// The view must declare and reference the interactor as a `@StateObject`. This allows different
/// instances of the view to reference the same interactor instance, therefore maintaining the states of the view's
/// data. This occurs when multiple instances of the same view are instantiated over time by SwiftUI, as the view
/// updates and changes due to data changes or user interactions. And because the interactor is a `@StateObject`,
/// the binding of the interactor via the `bind(observer:)` modifier must be inside the view's `body`.
///
/// In order to avoid SwiftUI retaining duplicate instances of the interactor, when the interactor is passed into the
/// view's constructor, it might be passed in as an `@autoclosure`. In other words, invoking the interactor's
/// constructor must be nested within the view's constructor:
///
///     func makeMyView() -> some View {
///       MyView(interactor: MyInteractor(...))
///     }
///
/// - Note: An `interactor` should NOT directly provide view data to the associated view. It should only contain
/// business logic. If the interactor needs to update the view with new data, it should provide the data to a
/// `ViewModel` that transforms it into presentation data for the view to display. Please see `ViewModelInteractor`
/// for details on this use case.
open class Interactor {
  /// Stores cancellables until deinit.
  let deinitCancelBag = SynchronizedCancelBag()
  /// Stores cancellables from view appearance and cancels all on view disappears.
  let viewAppearanceCancelBag = SynchronizedCancelBag()

  public private(set) var isLoaded = false
  // To avoid duplicate lifecycle function invocations.
  public private(set) var hasViewAppeared = false

  public init() {}
  /// Override this function to setup the subscriptions this interactor requires on start.
  ///
  /// All the created subscriptions returned from this function are bound to the deinit lifecycle of this interactor.
  ///
  ///     class MyInteractor: Interactor {
  ///       @CancellableBuilder
  ///       override func onLoad() -> [AnyCancellable] {
  ///         myDataStream
  ///           .sink {...}
  ///
  ///         mySecondDataStream
  ///           .sink {...}
  ///       }
  ///     }
  ///
  /// - Returns: An array of subscription `AnyCancellable`.
  @CancellableBuilder
  open func onLoad() -> [AnyCancellable] {}

  /// Override this function to perform logic or setup the subscriptions when the view has appeared.
  ///
  /// All the created subscriptions returned from this function are bound to the disappearance of this interactor's
  /// corresponding view.
  ///
  ///     class MyInteractor: Interactor {
  ///       @CancellableBuilder
  ///       override func onViewAppear() -> [AnyCancellable] {
  ///         myDataStream
  ///           .sink {...}
  ///
  ///         mySecondDataStream
  ///           .sink {...}
  ///       }
  ///     }
  ///
  /// - Returns: An array of subscription `AnyCancellable`.
  @CancellableBuilder
  open func onViewAppear() -> [AnyCancellable] {}

  /// Override this function to perform logic when the interactor's view disappears.
  open func onViewDisappear() {}

  deinit {
    deinitCancelBag.cancelAll()
    viewAppearanceCancelBag.cancelAll()
  }
}

// MARK: - ViewLifecycleObserver Conformance

extension Interactor: ViewLifecycleObserver {
  enum ViewEventOccurrence {
    case invalid
    case valid
    case firstTime
  }

  @discardableResult
  func processViewDidAppear() -> ViewEventOccurrence {
    guard !hasViewAppeared else {
      return .invalid
    }
    hasViewAppeared = true

    var occurrence = ViewEventOccurrence.valid
    if !isLoaded {
      isLoaded = true
      occurrence = .firstTime

      deinitCancelBag.store(onLoad())
    }

    viewAppearanceCancelBag.store(onViewAppear())

    return occurrence
  }

  @discardableResult
  func processViewDidDisappear() -> ViewEventOccurrence {
    guard hasViewAppeared else {
      return .invalid
    }
    hasViewAppeared = false

    viewAppearanceCancelBag.cancelAll()

    onViewDisappear()

    return .valid
  }

  public final func viewDidAppear() {
    processViewDidAppear()
  }

  public final func viewDidDisappear() {
    processViewDidDisappear()
  }
}

// MARK: - Why the responsibility of binding is left to the callsites

/// Instead of leaving the responsibility of binding to the callsites, a few other alternative implementations have
/// been attempted:
///
///   1. Using a wrapper view. This largely functions the same way as the view modifier. The wrapper view takes in an
///   interactor as an initializer parameter, and invokes the `bind` function on the content view in the the wrapper
///   view's `body` property. The interactor is then passed into the view builder to allow the content view to use
///   without having to separately instantiate the interactor. This however resulted in the callsites being quite
///   confusing to read:
///       InteractableView(interactor) { interactor
///        ContentView(interactor: interactor)
///       }
///
///   2. Perform the binding using plugin structures such as `OneOfPlugin` and `ForEachPlugin`. This approach required
///   significant compromises to get it to work.
///   - One implementation strategy is to declare a `View` sub-protocol that provides an interactor instance. This
///   would allow the plugin structures to invoke `bind` on the view using the view's interactor property. However,
///   since if the plugin wrapper view's `viewBuilder` implementation may contain conditionals, the resulting SwiftUI
///   internal `_ConditionalContent` would be required to conform to the sub-protocol. And since the
///   `_ConditionalContent` structure is an internal type, this extension conformance cannot be implemented.
///   - A second implementation strategy is to pass in the view builder and interactor builder closures separately.
///   This allows the plugin wrapper view to internally stitch together the two by mapping with the feature flag as
///   keys. Even though this implementation can work, it does make the callsite somewhat confusing by separating the
///   instantiations of views and their corresponding interactors:
///       ForEachPlugin(
///         featureFlags: MyFeatureFlag.allCases,
///         viewBuilder: { featureFlag in
///           switch featureFlag{
///           case .flag1: View1()
///           case .flag2: View2()
///         },
///         interactorBuilder: { featureFlag in
///           switch featureFlag{
///           case .flag1: Interactor1()
///           case .flag2: Interactor2()
///         }
///       )
///   A a major drawback to this approach is that in order to avoid instantiating two separate instances of an
///   interactor without making the callsite much more difficult, the interactor needs be assigned to the
///   corresponding view internally in the plugin wrapper view. There are two issues that make this assignment
///   difficult:
///     1. The `_ConditionalContent` issue of the plugin wrapper's view generic type described in the section above
///     still applies here. The view type cannot be constrained to anything other than the SwiftUI's native `View`.
///     2. The interactor cannot be assigned to the view via `@EnvironmentObject` since it would require a concrete
///     interactor type. And the plugin wrapper view cannot declare a generic constrain type for the interactor as it
///     would lock the all the views to a single interactor type,
///   The only viable solution to assign an interactor to its view, internally within the plugin wrapper view, is to
///   use a global map that stores the interactors with their names as keys. Then the view can retrieve the interactor
///   instance by first declaring an `associatedtype` of the interactor, then converting that type into a string key,
///   and finally retrieve the interactor from the global map with that key. This is NOT a compile-time safe operation
///   and error-prone.
///   3. Declare a `InteractableView` protocol and a default `interactable()` view modifier to perform the binding.
///   This unfortunately does not work due to Swift's type system. If the `InteractableView` protocol declares an
///   `associatedtype InteractorType: ViewLifecycleObserver`, the concrete view implementation is then required to
///   provide the `typealias` with a concrete class type. This means the view cannot be injected with a protocol.
///   In that case, the view is tightly coupled with the interactor implementation making use cases such as SwiftUI
///   previews impossible, since a  concrete interactor with all of its dependencies must be instantiated to create the
///   preview. If the the `InteractableView` protocol declares the interactor property as
///   `interactor: ViewLifecycleObserver { get }`, then it cannot be used as an argument for the `bind` function.
///   This is due to https://github.com/apple/swift-evolution/blob/main/proposals/0352-implicit-open-existentials.md
