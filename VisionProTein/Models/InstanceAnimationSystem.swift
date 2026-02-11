//
//  InstanceAnimationSystem.swift
//  VisionProTein
//
//  Created by Claude Code on 2/10/26.
//

import RealityKit

/// Registry for animation completion callbacks (since closures can't be stored in Components)
@MainActor
final class AnimationCallbackRegistry {
    static let shared = AnimationCallbackRegistry()
    private var callbacks: [String: () -> Void] = [:]

    func register(id: String, callback: @escaping () -> Void) {
        callbacks[id] = callback
    }

    func unregister(id: String) {
        callbacks.removeValue(forKey: id)
    }

    func invoke(id: String) {
        callbacks[id]?()
    }
}

/// System that updates mesh instance transforms for animations
class InstanceAnimationSystem: System {
    static let query = EntityQuery(where: .has(InstanceAnimationComponent.self) && .has(MeshInstancesComponent.self))

    required init(scene: Scene) { }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var animation = entity.components[InstanceAnimationComponent.self],
                  animation.playbackState == .playing || animation.playbackState == .reversing
            else { continue }

            // Calculate delta progress based on direction
            let delta = Float(context.deltaTime / animation.duration)
            var shouldFireCallback = false

            if animation.playbackState == .playing {
                animation.progress = min(1.0, animation.progress + delta)
                if animation.progress >= 1.0 {
                    animation.playbackState = .completed
                    shouldFireCallback = true
                }
            } else { // reversing
                animation.progress = max(0.0, animation.progress - delta)
                if animation.progress <= 0.0 {
                    animation.playbackState = .stopped
                    shouldFireCallback = true
                }
            }

            // Apply easing to get curved progress
            let easedProgress = animation.easing.apply(animation.progress)

            // Update mesh instance transforms
            updateInstanceTransforms(entity: entity, animation: animation, t: easedProgress)

            // Write back the updated component
            entity.components[InstanceAnimationComponent.self] = animation

            // Fire completion callback if needed
            if shouldFireCallback, let callbackID = animation.completionCallbackID {
                Task { @MainActor in
                    AnimationCallbackRegistry.shared.invoke(id: callbackID)
                }
            }
        }
    }

    private func updateInstanceTransforms(entity: Entity, animation: InstanceAnimationComponent, t: Float) {
        guard var meshInstances = entity.components[MeshInstancesComponent.self] else { return }

        // Access the first part (partIndex 0) - most entities have single part
        if var part = meshInstances[partIndex: 0] {
            part.data.withMutableTransforms { transforms in
                let count = min(transforms.count, animation.startTranslations.count, animation.endTranslations.count)
                for i in 0..<count {
                    // Lerp translation
                    let translation = mix(animation.startTranslations[i], animation.endTranslations[i], t: t)

                    // Update only the translation column of the transform matrix
                    transforms[i].columns.3 = SIMD4<Float>(translation, 1.0)
                }
            }
            // Write back the modified part
            meshInstances[partIndex: 0] = part
        }

        // Re-set the component to trigger update
        entity.components[MeshInstancesComponent.self] = meshInstances
    }
}

// MARK: - Entity Extension for Animation Control

extension Entity {
    /// Play the instance animation forward
    func playInstanceAnimation() {
        guard var anim = components[InstanceAnimationComponent.self] else { return }
        anim.playbackState = .playing
        components[InstanceAnimationComponent.self] = anim
    }

    /// Reverse the instance animation
    func reverseInstanceAnimation() {
        guard var anim = components[InstanceAnimationComponent.self] else { return }
        anim.playbackState = .reversing
        components[InstanceAnimationComponent.self] = anim
    }

    /// Reset animation to start position (t=0)
    func resetInstanceAnimation() {
        guard var anim = components[InstanceAnimationComponent.self] else { return }
        anim.progress = 0.0
        anim.playbackState = .stopped

        // Apply start transforms immediately
        if var meshInstances = components[MeshInstancesComponent.self] {
            if var part = meshInstances[partIndex: 0] {
                part.data.withMutableTransforms { transforms in
                    let count = min(transforms.count, anim.startTranslations.count)
                    for i in 0..<count {
                        transforms[i].columns.3 = SIMD4<Float>(anim.startTranslations[i], 1.0)
                    }
                }
                meshInstances[partIndex: 0] = part
            }
            components[MeshInstancesComponent.self] = meshInstances
        }

        components[InstanceAnimationComponent.self] = anim
    }

    /// Pause animation at current position
    func pauseInstanceAnimation() {
        guard var anim = components[InstanceAnimationComponent.self] else { return }
        anim.playbackState = .paused
        components[InstanceAnimationComponent.self] = anim
    }

    /// Set completion callback for this entity's animation
    @MainActor
    func setInstanceAnimationCompletion(_ callback: @escaping () -> Void) {
        let callbackID = "anim_\(ObjectIdentifier(self).hashValue)"
        AnimationCallbackRegistry.shared.register(id: callbackID, callback: callback)

        guard var anim = components[InstanceAnimationComponent.self] else { return }
        anim.completionCallbackID = callbackID
        components[InstanceAnimationComponent.self] = anim
    }
}
