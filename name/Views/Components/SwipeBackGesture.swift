//
//  SwipeBackGesture.swift
//  name
//
//  Created by Antigravity on 01/12/25.
//
//  DESCRIPTION:
//  Native iOS swipe-back navigation gesture enabler for views with hidden navigation bars.
//  Uses UIKit's native interactivePopGestureRecognizer for authentic iOS navigation feel.
//  
//  FEATURES:
//  - Native iOS parallax effect
//  - Shadow animations during swipe
//  - Smooth cancellation on partial swipe
//  - Haptic feedback (built into native gesture)
//  - Works even with navigationBarBackButtonHidden(true)
//  
//  USAGE:
//  ScrollView {
//      // content
//  }
//  .enableNativeSwipeBack()
//

import SwiftUI
import UIKit

// MARK: - Native Swipe Back Gesture

extension View {
    /// Enables native iOS swipe-back navigation gesture
    /// Works even when navigation back button is hidden
    func enableNativeSwipeBack() -> some View {
        self.background(NavigationControllerAccessor())
    }
}

// MARK: - Navigation Controller Accessor

/// UIViewControllerRepresentable that enables native swipe-back gesture
private struct NavigationControllerAccessor: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let navigationController = uiViewController.navigationController {
                // Enable the native swipe-back gesture
                navigationController.interactivePopGestureRecognizer?.isEnabled = true
                navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // Allow gesture to begin (always return true to enable swipe-back)
            return true
        }
        
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            // Give priority to the pop gesture over other gestures
            return true
        }
    }
}

