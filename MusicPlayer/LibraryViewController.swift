//
//  LibraryViewController.swift
//  MusicPlayer
//
//  Created by Jake Contreras on 1/8/19.
//  Copyright © 2019 Jake Contreras. All rights reserved.
//

import UIKit
import MediaPlayer

public var SongList: [AlbumCellInfo] = []
public var ArtistList: [AlbumCellInfo] = []
public var AlbumList: [AlbumCellInfo] = []
public var PlaylistList: [AlbumCellInfo] = []
class LibraryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var BackgroundView: UIVisualEffectView!
    @IBOutlet weak var ContentView: UIView!
    @IBOutlet weak var CollectionView: UICollectionView!
    @IBOutlet weak var ShuffleAllButton: UIButton!
    @IBOutlet weak var SortOptionPicker: UISegmentedControl!
    
    var BlurIn, BlurOut: UIViewPropertyAnimator!
    var ImpactFG = UIImpactFeedbackGenerator(style: .medium)
    
    var CollectionViewScrollPosition: CGFloat!
    
    var MusicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    var OriginalTransform, LargeTransform: CGAffineTransform!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OriginalTransform = ContentView.transform
        LargeTransform = ContentView.transform.scaledBy(x: 1.3, y: 1.3)
        
        BackgroundView.effect = nil
        ContentView.alpha = 0.0
        self.ContentView.transform = LargeTransform
        
        // Edit blur in effect
        BlurIn = UIViewPropertyAnimator(duration: 0.3, curve: .easeInOut, animations: {
            
            self.BackgroundView.effect = UIBlurEffect(style: .dark)
            self.ContentView.alpha = 1.0
            self.ContentView.transform = self.OriginalTransform
            
        })
        BlurIn.pausesOnCompletion = true
        
        // Edit blur out effect
        BlurOut = UIViewPropertyAnimator(duration: 0.3, curve: .linear, animations: {
            
            self.BackgroundView.effect = nil
            self.ContentView.alpha = 0.0
            self.ContentView.transform = self.LargeTransform
            
        })
        BlurOut.pausesOnCompletion = false
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start blur in effect
        BlurIn.fractionComplete = 0.0
        BlurIn.startAnimation()
        
        guard let CollectionViewScrollPosition = CollectionViewScrollPosition else { return }
        
        let Index = IndexPath(item: Int(CollectionViewScrollPosition / 112), section: 0)
        print("\(Index.item)")
        CollectionView.scrollToItem(at: Index, at: .top, animated: false)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        BlurIn.stopAnimation(true)
        BlurOut.stopAnimation(true)
        
        CollectionViewScrollPosition = CollectionView.contentOffset.y
        
    }
    
    // When the screen is pinched, close the Library screen
    var Pinched: Bool = false
    @IBAction func screenPinched(_ sender: UIPinchGestureRecognizer) {
        
        switch sender.state {
            
        case .began:
            ImpactFG.prepare()
            BlurOut.pauseAnimation()
            BlurOut.isReversed = false
            BlurOut.fractionComplete = 0.0
            BlurOut.addAnimations {
                
                self.BackgroundView.effect = nil
                self.ContentView.alpha = 0.0
                self.ContentView.transform = self.LargeTransform
                
            }
            
        case .changed:
            
            if Pinched == false {
                
                BlurOut.fractionComplete = sender.scale - 1.0
                
                // If the screen is pinched in, then hide the user's library
                if sender.scale > 1.5 {
                    
                    BlurOut.addCompletion { (_) in
                        
                        self.BlurIn.stopAnimation(true)
                        self.BlurIn.finishAnimation(at: .start)
                        self.dismiss(animated: false, completion: nil)
                        
                    }
                    BlurOut.continueAnimation(withTimingParameters: BlurOut.timingParameters, durationFactor: BlurOut.fractionComplete)
                    
                    DispatchQueue.main.async {
                        
                        self.ImpactFG.impactOccurred()
                        
                    }
                    Pinched = true
                    
                    CollectionViewScrollPosition = CollectionView.contentOffset.y
                    
                }
                
            }
            
        case .ended, .cancelled:
            if Pinched == true {
                
                Pinched = false
                
            } else {
                
                BlurOut.pauseAnimation()
                
                BlurOut.isReversed = true
                BlurOut.addCompletion { (_) in
                    
                    self.BlurOut.isReversed = false
                    
                }
                BlurOut.continueAnimation(withTimingParameters: BlurIn.timingParameters, durationFactor: (-BlurOut.fractionComplete + 2) / 1.5)
                
            }
            
        default:
            return
            
        }
        
    }
    
    // Collection view methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch SortOptionPicker.selectedSegmentIndex {
            
        case 0:
            return SongList.count
            
        case 1:
            return ArtistList.count
            
        case 2:
            return AlbumList.count
            
        case 3:
            return PlaylistList.count
            
        default:
            return 0
            
        }
        
    }
    
    let ReuseIdentifier = "AlbumCell"
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let Cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier, for: indexPath as IndexPath) as! AlbumCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        switch SortOptionPicker.selectedSegmentIndex {
            
        case 0:
            Cell.Image.image = SongList[indexPath.item].Image
            Cell.Title.text = SongList[indexPath.item].Title
            Cell.Artist.text = SongList[indexPath.item].Artist
            Cell.Album.text = SongList[indexPath.item].Album
            
        case 1:
            Cell.Image.image = ArtistList[indexPath.item].Image
            Cell.Title.text = ArtistList[indexPath.item].Title
            Cell.Artist.text = ArtistList[indexPath.item].Artist
            Cell.Album.text = ArtistList[indexPath.item].Album
            
        case 2:
            Cell.Image.image = AlbumList[indexPath.item].Image
            Cell.Title.text = AlbumList[indexPath.item].Title
            Cell.Artist.text = AlbumList[indexPath.item].Artist
            Cell.Album.text = AlbumList[indexPath.item].Album
            
        case 3:
            Cell.Image.image = PlaylistList[indexPath.item].Image
            Cell.Title.text = PlaylistList[indexPath.item].Title
            Cell.Artist.text = PlaylistList[indexPath.item].Artist
            Cell.Album.text = PlaylistList[indexPath.item].Album
            
        default:
            break
            
        }
        
        return Cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let Songs = MPMediaQuery.songs().items!
        MusicPlayer.setQueue(with: [Songs[indexPath.item].playbackStoreID])
        MusicPlayer.skipToNextItem()
        MusicPlayer.play()
        
        ImpactFG.impactOccurred()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.bounds.width, height: 100)
        
        
    }
    
    @IBAction func sortOptionChanged(_ sender: UISegmentedControl) {
        
        CollectionView.reloadData()
        
    }
    
    @IBAction func shuffleAllButtonPressed(_ sender: UIButton) {
        
        MusicPlayer.setQueue(with: MPMediaQuery.songs())
        MusicPlayer.shuffleMode = .songs
        MusicPlayer.play()
        
    }
    
}

// Collection view classes
public class AlbumCell: UICollectionViewCell {
    
    @IBOutlet weak var Image: UIImageView!
    @IBOutlet weak var Title: UILabel!
    @IBOutlet weak var Artist: UILabel!
    @IBOutlet weak var Album: UILabel!
    
}

public struct AlbumCellInfo {
    
    var Image: UIImage!
    var Title: String!
    var Artist: String!
    var Album: String!
    
}
