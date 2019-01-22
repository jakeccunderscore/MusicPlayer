//
//  NowPlayingViewController.swift
//  MusicPlayer
//
//  Created by Jake Contreras on 1/21/19.
//  Copyright © 2019 Jake Contreras. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class NowPlayingViewController: UIViewController {
    
    @IBOutlet weak var BackgroundImageView: UIImageView!
    @IBOutlet weak var AlbumImageView: UIView!
    @IBOutlet weak var AlbumImageImageView: UIImageView!
    
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var ArtistLabel: UILabel!
    @IBOutlet weak var AlbumLabel: UILabel!
    @IBOutlet weak var PlaybackTimeLabel: UILabel!
    @IBOutlet weak var TrackDurationLabel: UILabel!
    @IBOutlet weak var TrackProgressView: UIProgressView!
    
    var MusicPlayer = MPMusicPlayerController.systemMusicPlayer
    var Context = CIContext()
    
    var CurrentPlaybackTime: Double = 0.0
    
    let AnimationDuration = 0.35
    
    var ImpactFG = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var OldSongInfo = MusicPlayer.nowPlayingItem
        let UpdateTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { (_) in
            
            // If nothing is playing, display a "Not Playing" screen
            guard let NowPlaying = self.MusicPlayer.nowPlayingItem else {
                
                self.updateInfo(titleLabel: "Not Playing", artistLabel: "Tap to shuffle all songs", albumLabel: "", artworkImage: UIImage(named: "none_dark") ?? UIImage(), darkMode: .dark)
                return
                
            }
            
            // Set the playback times
            self.CurrentPlaybackTime = self.MusicPlayer.currentPlaybackTime
            self.PlaybackTimeLabel.text = self.formattedPlaybackTime()
            self.TrackProgressView.progress = Float(self.CurrentPlaybackTime / NowPlaying.playbackDuration)
            
            // If the song changed, update the info on screen
            if self.MusicPlayer.nowPlayingItem !== OldSongInfo || self.MusicPlayer.nowPlayingItem == nil {
                
                self.updateInfoWithNowPlayingItem()
                
            }
            
            // Animate the album art's size based on playback state
            switch self.MusicPlayer.playbackState {
                
            case .playing:
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                    
                    self.AlbumImageImageView.frame = self.AlbumImageView.bounds
                    
                }, completion: nil)
                
            case .paused, .interrupted, .stopped:
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveLinear], animations: {
                    
                    self.AlbumImageImageView.frame = self.AlbumImageView.bounds.insetBy(dx: 30, dy: 30)
                    
                }, completion: nil)
                
            default:
                return
                
            }
            
            // Update the old song info to compare to
            OldSongInfo = self.MusicPlayer.nowPlayingItem
            
        }
        UpdateTimer.fire()
        
        updateInfoWithNowPlayingItem()
        
        // Add a shadow to the album art
        AlbumImageView.layer.masksToBounds = false
        AlbumImageView.layer.shadowColor = UIColor.black.cgColor
        AlbumImageView.layer.shadowOffset = CGSize(width: 0, height: 10)
        AlbumImageView.layer.shadowRadius = 20
        AlbumImageView.layer.shadowOpacity = 0.3
        
    }
    
    // Play or pause music when the screen is tapped with one finger
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        
        if sender.state == .ended {
            
            switch MusicPlayer.playbackState {
                
            case .paused, .interrupted, .seekingForward, .seekingBackward, .stopped:
                MusicPlayer.play()
                
            case .playing:
                MusicPlayer.pause()
                
            }
            
            ImpactFG.impactOccurred()
            
        }
        
    }
    
    var OneFingerInitialX: CGFloat = 0.0
    var OneFingerDidTrigger: Bool = false
    @IBAction func screenPannedWithOneFinger(_ sender: UIPanGestureRecognizer) {
        
        switch sender.state {
            
        case .began:
            OneFingerInitialX = sender.location(in: sender.view).x
            
        case .changed:
            if OneFingerDidTrigger == false {
                
                if sender.location(in: sender.view).x > OneFingerInitialX + 20 {
                    
                    MusicPlayer.skipToNextItem()
                    
                    ImpactFG.impactOccurred()
                    
                    OneFingerDidTrigger = true
                    
                } else if sender.location(in: sender.view).x < OneFingerInitialX - 20 {
                    
                    if CurrentPlaybackTime < 3 {
                        
                        MusicPlayer.skipToPreviousItem()
                        
                    } else {
                        
                        MusicPlayer.skipToBeginning()
                        
                    }
                    
                    ImpactFG.impactOccurred()
                    
                    OneFingerDidTrigger = true
                    
                }
                
            }
            
        case .ended:
            OneFingerDidTrigger = false
            
        default:
            return
            
        }
        
    }
    
    // When the screen is pinched, open the Library screen
    var Pinched: Bool = false
    @IBAction func screenPinched(_ sender: UIPinchGestureRecognizer) {
        
        switch sender.state {
            
        case .began:
            ImpactFG.prepare()
            
        case .changed:
            
            if sender.scale < 0.8 && Pinched == false {
                
                performSegue(withIdentifier: "openLibrary", sender: self)
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
    
    func updateInfo(titleLabel: String, artistLabel: String, albumLabel: String, artworkImage: UIImage, darkMode: DarkModeOption) {
        
        // Create blurred version of artworkImage to use as a background
        guard
            let artworkCI = CIImage(image: artworkImage),
            let ColorControlsFilter = CIFilter(name: "CIColorControls"),
            let BlurFilter = CIFilter(name: "CIGaussianBlur"),
            let CropFilter = CIFilter(name: "CICrop")
            else { return }
        
        ColorControlsFilter.setValue(artworkCI, forKey: kCIInputImageKey)
        ColorControlsFilter.setValue(2, forKey: "inputSaturation")
        //        VibrancyFilter.setValue(0.2, forKey: "inputBrightness")
        
        BlurFilter.setValue(ColorControlsFilter.outputImage, forKey: kCIInputImageKey)
        BlurFilter.setValue(50, forKey: kCIInputRadiusKey)
        
        CropFilter.setValue(BlurFilter.outputImage, forKey: kCIInputImageKey)
        CropFilter.setValue(CIVector(cgRect: artworkCI.extent.insetBy(dx: BlurFilter.value(forKey: kCIInputRadiusKey) as! CGFloat * 1.8, dy: BlurFilter.value(forKey: kCIInputRadiusKey) as! CGFloat * 1.8)), forKey: "inputRectangle")
        
        guard let OutputImage = CropFilter.outputImage, let ArtworkCG = Context.createCGImage(OutputImage, from: OutputImage.extent) else { return }
        let artworkImageBlurred = UIImage(cgImage: ArtworkCG)
        
        Context.clearCaches()
        
        // Set album artwork, background, and labels
        UIView.transition(with: AlbumImageImageView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.AlbumImageImageView.image = artworkImage }, completion: nil)
        UIView.transition(with: BackgroundImageView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.BackgroundImageView.image = artworkImageBlurred }, completion: nil)
        
        UIView.transition(with: TitleLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TitleLabel.text = titleLabel }, completion: nil)
        UIView.transition(with: ArtistLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ArtistLabel.text = artistLabel }, completion: nil)
        UIView.transition(with: AlbumLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.AlbumLabel.text = albumLabel}, completion: nil)
        
        // Decide whether or not to enable dark mode
        var enableDarkMode = false
        switch darkMode {
            
        case .light:
            enableDarkMode = true
            
        case .dark:
            enableDarkMode = false
            
        case .auto:
            if artworkImageBlurred.isDark {
                
                enableDarkMode = true
                
            } else {
                
                enableDarkMode = false
                
            }
            
        }
        
        if enableDarkMode {
            
            UIView.transition(with: TitleLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TitleLabel.textColor = UIColor.white }, completion: nil)
            UIView.transition(with: ArtistLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ArtistLabel.textColor = UIColor.white }, completion: nil)
            UIView.transition(with: AlbumLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.AlbumLabel.textColor = UIColor.white}, completion: nil)
            
            UIView.transition(with: PlaybackTimeLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.PlaybackTimeLabel.textColor = UIColor.white}, completion: nil)
            UIView.transition(with: TrackDurationLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackDurationLabel.textColor = UIColor.white}, completion: nil)
            
            UIView.transition(with: TrackProgressView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackProgressView.progressTintColor = UIColor.white}, completion: nil)
            UIView.transition(with: TrackProgressView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackProgressView.trackTintColor = UIColor(white: 0.8, alpha: 0.5)}, completion: nil)
            
            StatusBarStyle = .lightContent
            setNeedsStatusBarAppearanceUpdate()
            
        } else {
            
            UIView.transition(with: TitleLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TitleLabel.textColor = UIColor.black }, completion: nil)
            UIView.transition(with: ArtistLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ArtistLabel.textColor = UIColor.black }, completion: nil)
            UIView.transition(with: AlbumLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.AlbumLabel.textColor = UIColor.black}, completion: nil)
            
            UIView.transition(with: PlaybackTimeLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.PlaybackTimeLabel.textColor = UIColor.black}, completion: nil)
            UIView.transition(with: TrackDurationLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackDurationLabel.textColor = UIColor.black}, completion: nil)
            
            UIView.transition(with: TrackProgressView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackProgressView.progressTintColor = UIColor.black}, completion: nil)
            UIView.transition(with: TrackProgressView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackProgressView.trackTintColor = UIColor(white: 0.3, alpha: 0.3)}, completion: nil)
            
            StatusBarStyle = .default
            setNeedsStatusBarAppearanceUpdate()
            
        }
        
        TrackDurationLabel.text = formattedPlaybackDuration()
        
    }
    
    func updateInfoWithNowPlayingItem() {
        
        guard
            let NowPlaying = self.MusicPlayer.nowPlayingItem,
            let Title = NowPlaying.title,
            let Artist = NowPlaying.artist,
            let Album = NowPlaying.albumTitle,
            let Artwork = NowPlaying.artwork?.image(at: self.MusicPlayer.nowPlayingItem?.artwork?.bounds.size ?? CGSize(width: 1024, height: 1024))
            else { return }
        
        self.updateInfo(titleLabel: Title, artistLabel: Artist, albumLabel: Album, artworkImage: Artwork, darkMode: .auto)
        
    }
    
    func formattedPlaybackTime() -> String {
        
        let ElapsedTime = CurrentPlaybackTime
        let ElapsedTimeMinutes = Int(ElapsedTime / 60)
        let ElapsedTimeSeconds = Int(ElapsedTime.truncatingRemainder(dividingBy: 60))
        
        if ElapsedTimeSeconds < 10 {
            
            return "\(ElapsedTimeMinutes):0\(ElapsedTimeSeconds)"
            
        } else {
            
            return "\(ElapsedTimeMinutes):\(ElapsedTimeSeconds)"
            
        }
        
    }
    
    func formattedPlaybackDuration() -> String {
        
        guard let NowPlaying = MusicPlayer.nowPlayingItem else { return "00:00" }
        
        let ElapsedTime = NowPlaying.playbackDuration
        let ElapsedTimeMinutes = Int(ElapsedTime / 60)
        let ElapsedTimeSeconds = Int(ElapsedTime.truncatingRemainder(dividingBy: 60))
        
        if ElapsedTimeSeconds < 10 {
            
            return "\(ElapsedTimeMinutes):0\(ElapsedTimeSeconds)"
            
        } else {
            
            return "\(ElapsedTimeMinutes):\(ElapsedTimeSeconds)"
            
        }
        
    }
    
    var StatusBarStyle: UIStatusBarStyle = .default
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        return self.StatusBarStyle
        
    }
    
    var HomeIndicatorHidden: Bool = false
    override var prefersHomeIndicatorAutoHidden: Bool {
        
        return self.HomeIndicatorHidden
        
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        
        return .fade
        
    }
    
}
