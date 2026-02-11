//
//  InstanceAnimationComponent.swift
//  VisionProTein
//
//  Created by Claude Code on 2/10/26.
//

import Foundation
import RealityKit

/// Easing functions for animations
enum AnimationEasing: Codable, Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut

    /// Apply easing to linear progress (0.0 to 1.0)
    func apply(_ t: Float) -> Float {
        switch self {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .easeOut:
            return 1 - (1 - t) * (1 - t)
        case .easeInOut:
            return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        }
    }
}

/// Playback state of the animation
enum AnimationPlaybackState: Codable, Sendable {
    case stopped      // At start position (t=0)
    case playing      // Animating forward
    case reversing    // Animating backward
    case paused       // Frozen at current t
    case completed    // At end position (t=1)
}

/// Component that stores animation state for mesh instances
struct InstanceAnimationComponent: Component {
    /// Per-instance start translations (local to parent entity)
    var startTranslations: [SIMD3<Float>]

    /// Per-instance end translations (local to parent entity)
    var endTranslations: [SIMD3<Float>]

    /// Current animation progress (0.0 to 1.0)
    var progress: Float = 0.0

    /// Animation duration in seconds
    var duration: TimeInterval = 1.0

    /// Easing function
    var easing: AnimationEasing = .easeInOut

    /// Current playback state
    var playbackState: AnimationPlaybackState = .stopped

    /// Callback identifier for completion (stored as string, looked up in registry)
    var completionCallbackID: String?

    init(
        startTranslations: [SIMD3<Float>],
        endTranslations: [SIMD3<Float>],
        duration: TimeInterval = 1.0,
        easing: AnimationEasing = .easeInOut
    ) {
        self.startTranslations = startTranslations
        self.endTranslations = endTranslations
        self.duration = duration
        self.easing = easing
    }
}
