//
//  Buzz.swift
//  RocketJump
//
//  Haptic punctuation. Free function namespace, no shared instance — feedback
//  generators are cheap and meant to be short-lived.
//

import UIKit

enum Buzz {

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func knock() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func thud() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func chime() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func alarm() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
