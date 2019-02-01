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
    
    @IBOutlet weak var RepeatButton: UIButton!
    @IBOutlet weak var ShuffleButton: UIButton!
    
    // Used for controlling and reading music playback and info
    var MusicPlayer = MPMusicPlayerController.systemMusicPlayer
    var Context = CIContext()
    
    var OldSongInfo: MPMediaItem!
    var OldPlaybackState: MPMusicPlaybackState!
    var OldRepeatMode: MPMusicRepeatMode!
    var OldShuffleMode: MPMusicShuffleMode!
    
    var CurrentPlaybackTime: Double = 0.0
    
    // Global animation speed variable - decrease for faster animations, increase for slower ones
    let AnimationDuration = 0.35
    
    // Used for all gestures
    var ImpactFG = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set initial OldSongInfo and OldPlaybackState
        // (they'll be changed later, they just need an initial value)
        OldSongInfo = MusicPlayer.nowPlayingItem
        OldPlaybackState = MusicPlayer.playbackState
        OldRepeatMode = MusicPlayer.repeatMode
        OldShuffleMode = MusicPlayer.shuffleMode
        
        // Create and start the timer to update info automatically
        let UpdateTimer = Timer.scheduledTimer(timeInterval: 1/30, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        UpdateTimer.fire()
        
        // Add a shadow to the album art
        AlbumImageView.layer.masksToBounds = false
        AlbumImageView.layer.shadowColor = UIColor.black.cgColor
        AlbumImageView.layer.shadowOffset = CGSize(width: 0, height: 10)
        AlbumImageView.layer.shadowRadius = 20
        AlbumImageView.layer.shadowOpacity = 0.3
        
    }
    
    // Refresh data when the app is brought back to the foreground
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refresh()
        updateInfoWithNowPlayingItem()
        updateRepeatButton()
        updateShuffleButton()
        
    }
    
    // Play or pause music when the screen is tapped with one finger
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        
        if sender.state == .ended {
            
            switch MusicPlayer.playbackState {
                
            case .paused, .interrupted, .seekingForward, .seekingBackward, .stopped:
                MusicPlayer.play()
                
            case .playing:
                MusicPlayer.pause()
                
            default:
                return
                
            }
            
            ImpactFG.impactOccurred()
            
        }
        
    }
    
    // When the screen is panned with one finger, skip tracks
    var OneFingerInitialX: CGFloat = 0.0
    var OneFingerDidTrigger: Bool = false
    var OneFingerAlbumImageImageViewInitialX: CGFloat = 0.0
    
    // Threshold for the gesture
    let OneFingerThreshold: CGFloat = 60
    @IBAction func screenPannedWithOneFinger(_ sender: UIPanGestureRecognizer) {
        
        switch sender.state {
            
        case .began:
            // Record the initial position of the finger and the initial x-position of the album art
            OneFingerInitialX = sender.location(in: sender.view).x
            OneFingerAlbumImageImageViewInitialX = AlbumImageImageView.frame.minX
            
            ImpactFG.prepare()
            
        case .changed:
            // If the skip gesture hasn't been activated yet...
            if OneFingerDidTrigger == false {
                
                // Adjust the position of the album art with the finger's position
                // as if it was being slid left and right
                let Difference = sender.location(in: sender.view).x - OneFingerInitialX
                AlbumImageImageView.frame = CGRect(x: OneFingerAlbumImageImageViewInitialX + Difference / 2, y: AlbumImageImageView.frame.minY, width: AlbumImageImageView.frame.width, height: AlbumImageImageView.frame.height)
                
                // Skip forwards to next song
                if Difference > OneFingerThreshold {
                    
                    MusicPlayer.skipToNextItem()
                    
                    ImpactFG.impactOccurred()
                    
                    OneFingerDidTrigger = true
                    resetAlbumImageImageViewLocation()
                    
                // Skip backwards to beginning of song or previous track
                } else if Difference < -OneFingerThreshold {
                    
                    if CurrentPlaybackTime < 3 {
                        
                        MusicPlayer.skipToPreviousItem()
                        
                    } else {
                        
                        MusicPlayer.skipToBeginning()
                        
                    }
                    
                    ImpactFG.impactOccurred()
                    
                    OneFingerDidTrigger = true
                    resetAlbumImageImageViewLocation()
                    
                }
                
            }
            
        case .ended:
            // When the finger's touch has ended
            OneFingerDidTrigger = false
            resetAlbumImageImageViewLocation()
            
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
            
            // If the screen is pinched out, then show the user's library
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
    
    func resetAlbumImageImageViewLocation() {
        
        switch MusicPlayer.playbackState {
            
        case .playing:
            // If music is currently playing, display a regular size album art
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                
                self.AlbumImageImageView.frame = self.AlbumImageView.bounds
                
            }, completion: nil)
            
        case .paused, .interrupted, .stopped:
            // If music is currently stopped, display a slightly smaller album art
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                
                self.AlbumImageImageView.frame = self.AlbumImageView.bounds.insetBy(dx: 30, dy: 30)
                
            }, completion: nil)
            
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
        
        if enableDarkMode == true {
            
            UIView.transition(with: PlaybackTimeLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.PlaybackTimeLabel.textColor = UIColor.white}, completion: nil)
            UIView.transition(with: TrackDurationLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackDurationLabel.textColor = UIColor.white}, completion: nil)
            
            UIView.transition(with: TrackProgressView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackProgressView.progressTintColor = UIColor.white}, completion: nil)
            UIView.transition(with: TrackProgressView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackProgressView.trackTintColor = UIColor(white: 1.0, alpha: 0.5)}, completion: nil)
            
            StatusBarStyle = .lightContent
            setNeedsStatusBarAppearanceUpdate()
            
            UIView.transition(with: TitleLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TitleLabel.textColor = UIColor.white }, completion: nil)
            UIView.transition(with: ArtistLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ArtistLabel.textColor = UIColor.white }, completion: nil)
            UIView.transition(with: AlbumLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.AlbumLabel.textColor = UIColor.white}, completion: nil)
            
        } else {
            
            UIView.transition(with: PlaybackTimeLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.PlaybackTimeLabel.textColor = UIColor.black}, completion: nil)
            UIView.transition(with: TrackDurationLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackDurationLabel.textColor = UIColor.black}, completion: nil)
            
            UIView.transition(with: TrackProgressView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackProgressView.progressTintColor = UIColor.black}, completion: nil)
            UIView.transition(with: TrackProgressView, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TrackProgressView.trackTintColor = UIColor(white: 0.0, alpha: 0.5)}, completion: nil)
            
            StatusBarStyle = .default
            setNeedsStatusBarAppearanceUpdate()
            
            UIView.transition(with: TitleLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.TitleLabel.textColor = UIColor.black }, completion: nil)
            UIView.transition(with: ArtistLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ArtistLabel.textColor = UIColor.black }, completion: nil)
            UIView.transition(with: AlbumLabel, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.AlbumLabel.textColor = UIColor.black}, completion: nil)
            
        }
        
        TrackDurationLabel.text = formattedPlaybackDuration()
        
        updateRepeatButton()
        updateShuffleButton()
        
    }
    
    func updateInfoWithNowPlayingItem() {
        
        guard
            let NowPlaying = self.MusicPlayer.nowPlayingItem,
            let Title = NowPlaying.title,
            let Artist = NowPlaying.artist,
            let Album = NowPlaying.albumTitle,
            let Artwork = NowPlaying.artwork?.image(at: NowPlaying.artwork!.bounds.size)
            else { return }
        
        // Updates the info with the currently playing song
        self.updateInfo(titleLabel: Title, artistLabel: Artist, albumLabel: Album, artworkImage: Artwork, darkMode: .auto)
        
    }
    
    
    @objc func refresh() {
        
        // If nothing is playing, display a "Not Playing" screen
        guard let NowPlaying = self.MusicPlayer.nowPlayingItem else {
            
            self.updateInfo(titleLabel: "Not Playing", artistLabel: "Tap to shuffle all songs", albumLabel: "", artworkImage: UIImage(), darkMode: .dark)
            return
            
        }
        
        // Set the playback times
        self.CurrentPlaybackTime = self.MusicPlayer.currentPlaybackTime
        self.PlaybackTimeLabel.text = self.formattedPlaybackTime()
        self.TrackProgressView.progress = Float(self.CurrentPlaybackTime / NowPlaying.playbackDuration)
        
        // If the song changed, update the info on screen
        if self.MusicPlayer.nowPlayingItem != OldSongInfo || self.MusicPlayer.nowPlayingItem == nil {
            
            self.updateInfoWithNowPlayingItem()
            
        }
        
        // Animate the album art's size based on playback state
        
        if self.MusicPlayer.playbackState != OldPlaybackState {
            
            self.resetAlbumImageImageViewLocation()
            
        }
        
        if self.MusicPlayer.repeatMode != OldRepeatMode {
            
            self.updateRepeatButton()
            
        }
        
        if self.MusicPlayer.shuffleMode != OldShuffleMode {
            
            self.updateShuffleButton()
            
        }
        
        // Update the old song info to compare to
        OldSongInfo = self.MusicPlayer.nowPlayingItem
        OldPlaybackState = self.MusicPlayer.playbackState
        OldRepeatMode = MusicPlayer.repeatMode
        OldShuffleMode = MusicPlayer.shuffleMode
        
    }
    
    func updateRepeatButton() {
        
        switch MusicPlayer.repeatMode {
            
        case .one:
            switch BackgroundImageView.image!.isDark {
                
            case true:
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.imageView!.image = UIImage(named: "repeat_one_light") }, completion: nil)
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.alpha = 1.0 }, completion: nil)
                
            case false:
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.imageView!.image = UIImage(named: "repeat_one_dark") }, completion: nil)
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.alpha = 1.0 }, completion: nil)
                
            }
            
        case .all:
            switch BackgroundImageView.image!.isDark {
                
            case true:
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.imageView!.image = UIImage(named: "repeat_light") }, completion: nil)
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.alpha = 1.0 }, completion: nil)
                
            case false:
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.imageView!.image = UIImage(named: "repeat_dark") }, completion: nil)
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.alpha = 1.0 }, completion: nil)
                
            }
            
        default:
            switch BackgroundImageView.image!.isDark {
                
            case true:
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.imageView!.image = UIImage(named: "repeat_light") }, completion: nil)
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.alpha = 0.5 }, completion: nil)
                
            case false:
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.imageView!.image = UIImage(named: "repeat_dark") }, completion: nil)
                UIView.transition(with: RepeatButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.RepeatButton.alpha = 0.5 }, completion: nil)
                
            }
            
        }
        
    }
    
    func updateShuffleButton() {
        
        switch BackgroundImageView.image!.isDark {
            
        case true:
            UIView.transition(with: ShuffleButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ShuffleButton.imageView!.image = UIImage(named: "shuffle_light") }, completion: nil)
            switch MusicPlayer.shuffleMode {
                
            case .albums, .songs:
                UIView.transition(with: ShuffleButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ShuffleButton.alpha = 1.0 }, completion: nil)
                
            default:
                UIView.transition(with: ShuffleButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ShuffleButton.alpha = 0.5 }, completion: nil)
                
            }
            
        case false:
            UIView.transition(with: ShuffleButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ShuffleButton.imageView!.image = UIImage(named: "shuffle_dark") }, completion: nil)
            switch MusicPlayer.shuffleMode {
                
            case .albums, .songs:
                UIView.transition(with: ShuffleButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ShuffleButton.alpha = 1.0 }, completion: nil)
                
            default:
                UIView.transition(with: ShuffleButton, duration: AnimationDuration, options: .transitionCrossDissolve, animations: { self.ShuffleButton.alpha = 0.5 }, completion: nil)
                
            }
            
        }
        
    }
    
    @IBAction func repeatButtonPressed(_ sender: UIButton) {
        
        switch MusicPlayer.repeatMode {
            
        case .none:
            MusicPlayer.repeatMode = .all
            
        case .all:
            MusicPlayer.repeatMode = .one
            
        default:
            MusicPlayer.repeatMode = .none
            
        }
        
        ImpactFG.impactOccurred()
        
    }
    
    @IBAction func shuffleButtonPressed(_ sender: UIButton) {
        
        switch MusicPlayer.shuffleMode {
            
        case .songs, .albums:
            MusicPlayer.shuffleMode = .off
            
        default:
            MusicPlayer.shuffleMode = .songs
            
        }
        
        ImpactFG.impactOccurred()
        
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
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        
        return .fade
        
    }
    
}
