/// A type that can load and subscribe to state in an external system.
///
/// Conform to this protocol to express loading state from an external system, and subscribing to
/// state changes in the external system. It is only necessary to conform to this protocol if the
/// ``appStorage(_:)-2ntx6``, ``fileStorage(_:)`` or ``inMemory(_:)`` strategies are not sufficient
/// for your use case.
///
/// See the article <doc:SharingState> for more information, in particular the
/// <doc:SharingState#Custom-persistence> section.
public protocol PersistenceReaderKey<Value>: Hashable {
  associatedtype Value

  /// Loads the freshest value from storage. Returns `nil` if there is no value in storage.
  func load(initialValue: Value?) -> Value?  // TODO: Should this be throwing?

  /// Subscribes to external updates.
  func subscribe(
    initialValue: Value?,
    didSet: @Sendable @escaping (_ newValue: Value?) -> Void
  ) -> Shared<Value>.Subscription
}

extension PersistenceReaderKey {
  public func subscribe(
    initialValue: Value?,
    didSet: @Sendable @escaping (_ newValue: Value?) -> Void
  ) -> Shared<Value>.Subscription {
    Shared.Subscription {}
  }
}

/// A type that can persist shared state to an external storage.
///
/// Conform to this protocol to express persistence to some external storage by describing how to
/// save to and load from the external storage, and providing a stream of values that represents
/// when the external storage is changed from the outside. It is only necessary to conform to
/// this protocol if the ``appStorage(_:)-2ntx6``, ``fileStorage(_:)`` or ``inMemory(_:)``
/// strategies are not sufficient for your use case.
///
/// See the article <doc:SharingState> for more information, in particular the
/// <doc:SharingState#Custom-persistence> section.
public protocol PersistenceKey<Value>: PersistenceReaderKey {
  /// Saves a value to storage.
  func save(_ value: Value)
}

extension Shared {
  public class Subscription {
    let onCancel: () -> Void
    public init(onCancel: @escaping () -> Void) {
      self.onCancel = onCancel
    }
    deinit {
      self.cancel()
    }
    /// Cancels this subscription.
    public func cancel() {
      self.onCancel()
    }
  }
}
