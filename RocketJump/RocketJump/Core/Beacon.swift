//
//  Beacon.swift
//  RocketJump
//
//  A minimal typed signal hub. Not a global manager — instances are owned by
//  whoever needs a conversation (a flight session owns one, the shell owns
//  another). Observers get a token; dropping the token ends the subscription.
//

import Foundation

/// One channel of a given payload type.
final class Beacon<Payload> {

    private var sinks: [UUID: (Payload) -> Void] = [:]

    @discardableResult
    func listen(_ sink: @escaping (Payload) -> Void) -> Subscription {
        let id = UUID()
        sinks[id] = sink
        return Subscription { [weak self] in self?.sinks[id] = nil }
    }

    func relay(_ payload: Payload) {
        for sink in sinks.values { sink(payload) }
    }

    // @inline(never): workaround for Swift 6.3.2 EarlyPerfInliner crash on
    // generic deinit with function-typed stored properties (rdar://compiler-bug).
    @inline(never)
    func silence() { sinks.removeAll() }

    deinit { silence() }
}

/// Lifetime handle for a listener. Keep it alive to keep listening.
final class Subscription {
    private let cancel: () -> Void
    private var spent = false
    init(_ cancel: @escaping () -> Void) { self.cancel = cancel }
    func drop() { guard !spent else { return }; spent = true; cancel() }
    deinit { drop() }
}

/// Holds subscriptions so a controller can release them all at once.
final class SignalBag {
    private var held: [Subscription] = []
    func keep(_ s: Subscription) { held.append(s) }
    func empty() { held.forEach { $0.drop() }; held.removeAll() }
    deinit { empty() }
}
