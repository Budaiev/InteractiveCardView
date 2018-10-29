//
//  ViewController.swift
//  CardView
//
//  Created by Maxim Kovalko on 10/29/18.
//  Copyright © 2018 Maxim Kovalko. All rights reserved.
//

import UIKit

private let cardHeight: CGFloat = 600
private let cardHandleAreaHeight: CGFloat = 65
private let transitionDuration: TimeInterval = 0.9
private let cornerRadius: CGFloat = 12

extension ViewController {
    enum CardState {
        case expanded
        case collapsed
    }
}

class ViewController: UIViewController {
    
    @IBOutlet private var imageView: UIImageView!
    
    var cardViewController: CardViewController!
    var visualEffectView: UIVisualEffectView!
    
    var cardVisible = false
    
    var nextState: CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCard()
    }
    
    func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = view.frame
        view.addSubview(visualEffectView)
        
        cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)
        addChildViewController(cardViewController)
        view.addSubview(cardViewController.view)
        
        cardViewController.view.frame = CGRect(
            x: 0,
            y: view.frame.height - cardHandleAreaHeight,
            width: view.frame.width,
            height: cardHeight
        )
        
        cardViewController.view.clipsToBounds = true
        
        [UITapGestureRecognizer(target: self, action: #selector(handleCardTap)),
         UIPanGestureRecognizer(target: self, action: #selector(handleCardPan))
        ].forEach { cardViewController.handleArea.addGestureRecognizer($0) }
    }
    
    @objc
    func handleCardTap(recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        animateTransitionIfNeeded(state: nextState, duration: transitionDuration)
    }
    
    @objc
    func handleCardPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            //start transition
            startInteractiveTransition(state: nextState, duration: transitionDuration)
        case .changed:
            //update transition
            let translation = recognizer.translation(in: cardViewController.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            //continue transition
            continueInteractiveTransition()
        default:
            break
        }
    }

}

//MARK: - Configure Animators

private extension ViewController {
    func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        guard runningAnimations.isEmpty else { return }
        
        var frameAnimator: UIViewPropertyAnimator {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y
                        = self.view.frame.height - cardHeight
                case .collapsed:
                    self.cardViewController.view.frame.origin.y
                        = self.view.frame.height - cardHandleAreaHeight
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            return frameAnimator
        }
        
        var cornerRadiusAnimator: UIViewPropertyAnimator {
            return UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = cornerRadius
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
        }
        
        var blurAnimator: UIViewPropertyAnimator {
            return UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
        }
        
        [frameAnimator, cornerRadiusAnimator, blurAnimator].forEach {
            $0.startAnimation()
            runningAnimations += [$0]
        }
    }
}

//MARK: - Perform Animation

private extension ViewController {
    func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            //run animation
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        runningAnimations.forEach {
            $0.pauseAnimation()
            animationProgressWhenInterrupted = $0.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted: CGFloat) {
        runningAnimations.forEach {
            $0.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition() {
        runningAnimations.forEach {
            $0.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}
