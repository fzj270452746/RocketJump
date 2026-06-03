//
//  Glide.swift
//  RocketJump
//
//  Custom navigation transition — surfaces glide and fade rather than the
//  stock UIKit slide, so the app's page changes read as one cohesive motion
//  language distinct from system chrome.
//

import UIKit

final class Glide: NSObject, UIViewControllerAnimatedTransitioning,
                   UINavigationControllerDelegate {

    private let popping: Bool
    init(popping: Bool) { self.popping = popping }

    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.42 }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let to = ctx.view(forKey: .to), let from = ctx.view(forKey: .from) else {
            ctx.completeTransition(false); return
        }
        let container = ctx.containerView
        let shift = container.bounds.width * 0.22

        if popping {
            container.insertSubview(to, belowSubview: from)
            to.transform = CGAffineTransform(translationX: -shift, y: 0)
            to.alpha = 0.6
            UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.86,
                           initialSpringVelocity: 0.3, options: .curveEaseOut) {
                from.transform = CGAffineTransform(translationX: container.bounds.width, y: 0)
                from.alpha = 0.4
                to.transform = .identity
                to.alpha = 1
            } completion: { _ in
                from.transform = .identity
                ctx.completeTransition(!ctx.transitionWasCancelled)
            }
        } else {
            container.addSubview(to)
            to.transform = CGAffineTransform(translationX: shift, y: 24).scaledBy(x: 0.98, y: 0.98)
            to.alpha = 0
            UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.82,
                           initialSpringVelocity: 0.4, options: .curveEaseOut) {
                from.transform = CGAffineTransform(translationX: -shift * 0.5, y: 0)
                from.alpha = 0.5
                to.transform = .identity
                to.alpha = 1
            } completion: { _ in
                from.transform = .identity
                from.alpha = 1
                ctx.completeTransition(!ctx.transitionWasCancelled)
            }
        }
    }

    func navigationController(_ nav: UINavigationController,
                              animationControllerFor op: UINavigationController.Operation,
                              from: UIViewController, to: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        Glide(popping: op == .pop)
    }
}
