//
//  Extensions.swift
//  MusicPlayer
//
//  Created by Jake Contreras on 1/21/19.
//  Copyright © 2019 Jake Contreras. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreGraphics

enum DarkModeOption {
    
    case light
    case dark
    case auto
    
}

extension CGImage {
    
    // Detect if an image (mainly artwork) is consisted of mostly dark pixels or light pixels
    // Used in DarkModeOption.auto to automatically set the interface style
    var isDark: Bool {
        
        get {
            
            guard let ImageData = self.dataProvider?.data else { return false }
            guard let Ptr = CFDataGetBytePtr(ImageData) else { return false }
            
            let Length = CFDataGetLength(ImageData)
            let Threshold = Int(Double(self.width * self.height) * 0.6)
            var DarkPixels = 0
            
            for i in stride(from: 0, to: Length, by: 4) {
                
                let r = Ptr[i]
                let g = Ptr[i + 1]
                let b = Ptr[i + 2]
                let Luminance = (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                
                if Luminance < 150 {
                    
                    DarkPixels += 1
                    if DarkPixels > Threshold {
                        
                        return true
                        
                    }
                    
                }
                
            }
            
            return false
            
        }
        
    }
    
}

extension UIImage {
    
    // Allow the user to check if a UIImage is dark or not, uses above methods
    var isDark: Bool {
        
        get {
            
            return self.cgImage?.isDark ?? false
            
        }
        
    }
    
}

extension MPVolumeView {
    
    static func setVolume(_ volume: Float) {
        
        let VolumeView = MPVolumeView()
        let Slider = VolumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            
            Slider?.value = volume
            
        }
        
    }
    
}
