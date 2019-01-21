//
//  LibraryViewController.swift
//  MusicPlayer
//
//  Created by Jake Contreras on 1/8/19.
//  Copyright © 2019 Jake Contreras. All rights reserved.
//

import UIKit
import MediaPlayer

class LibraryViewController: UIViewController {
    
    @IBOutlet weak var BackgroundView: UIVisualEffectView!
    @IBOutlet weak var BackgroundContentView: UIView!
    
    var BlurIn, BlurOut: UIViewPropertyAnimator!
    
    var ImpactFG = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BackgroundView.effect = nil
        BackgroundContentView.alpha = 0.0
        
        // Edit blur in effect
        BlurIn = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
            
            self.BackgroundView.effect = UIBlurEffect(style: .dark)
            self.BackgroundContentView.alpha = 1.0
            
        })
        
        // Edit blur out effect
        BlurOut = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut, animations: {
            
            self.BackgroundView.effect = nil
            self.BackgroundContentView.alpha = 0.0
            
        })
        BlurOut.addCompletion { (_) in
            
            self.dismiss(animated: false, completion: nil)
            
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        BlurIn.fractionComplete = 0.0
        BlurIn.startAnimation()
        
    }
    
    var Pinched: Bool = false
    @IBAction func screenPinched(_ sender: UIPinchGestureRecognizer) {
        
        switch sender.state {
            
        case .began:
            ImpactFG.prepare()
            
        case .changed:
            
            if sender.scale > 1.2 && Pinched == false {
                
                BlurOut.fractionComplete = 0.0
                BlurOut.startAnimation()
                DispatchQueue.main.async {
                    
                    self.ImpactFG.impactOccurred()
                    
                }
                Pinched = true
                
            }
            
        case .ended, .cancelled:
            Pinched = false
            
        default:
            return
            
        }
        
    }
    
}
