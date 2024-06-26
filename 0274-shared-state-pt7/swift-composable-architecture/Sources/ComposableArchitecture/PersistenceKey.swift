import Foundation

public protocol PersistenceKey<Value>: Hashable {
  associatedtype Value
  func load() -> Value?
  func save(_ value: Value)
  var updates: AsyncStream<Value> { get }
}

public struct InMemoryKey<Value>: PersistenceKey {
  let key: String
  public func load() -> Value? { nil }
  public func save(_ value: Value) {}
  public var updates: AsyncStream<Value> { .finished }
}

private enum DefaultAppStorageKey: DependencyKey {
  static let liveValue = UncheckedSendable(UserDefaults.standard)
  static var testValue: UncheckedSendable<UserDefaults> {
    let suiteName = "pointfree.co"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return UncheckedSendable(defaults)
  }
}

extension DependencyValues {
  public var defaultAppStorage: UserDefaults {
    get { self[DefaultAppStorageKey.self].value }
    set { self[DefaultAppStorageKey.self].value = newValue }
  }
}

public struct AppStorageKey<Value>: PersistenceKey {
  @Dependency(\.defaultAppStorage) var defaultAppStorage
  let key: String
  public init(key: String) {
    self.key = key
  }
  public func load() -> Value? {
    defaultAppStorage.value(forKey: self.key) as? Value
  }
  public func save(_ value: Value) {
    defaultAppStorage.setValue(value, forKey: self.key)
  }
  public var updates: AsyncStream<Value> {
    AsyncStream { continuation in
      let observer = Observer(continuation: continuation)
      defaultAppStorage.addObserver(
        observer,
        forKeyPath: self.key,
        options: [.new],
        context: nil
      )
      continuation.onTermination = { _ in
        defaultAppStorage.removeObserver(observer, forKeyPath: self.key)
      }
    }
  }
  public static func == (lhs: AppStorageKey, rhs: AppStorageKey) -> Bool {
    lhs.key == rhs.key
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.key)
  }

  class Observer: NSObject {
    let continuation: AsyncStream<Value>.Continuation
    init(continuation: AsyncStream<Value>.Continuation) {
      self.continuation = continuation
    }
    override func observeValue(
      forKeyPath keyPath: String?,
      of object: Any?,
      change: [NSKeyValueChangeKey : Any]?,
      context: UnsafeMutableRawPointer?
    ) {
      guard let value = change?[.newKey] as? Value
      else { return }
      self.continuation.yield(value)
    }
  }
}

extension PersistenceKey {
  public static func appStorage<Value>(
    _ key: String
  ) -> Self where Self == AppStorageKey<Value> {
    AppStorageKey(key: key)
  }

  public static func inMemory<Value>(
    _ key: String
  ) -> Self where Self == InMemoryKey<Value> {
    InMemoryKey(key: key)
  }
}
