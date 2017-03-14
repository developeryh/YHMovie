
//  YHMovieManager.swift
//  YHMovieViewDemo
//
//  Created by srgroup on 16/5/12.
//  Copyright © 2016年 developeryh. All rights reserved.
//

import UIKit
import AVFoundation

//单例
private let shareYHMovieManager = YHMovieManager()
final class YHMovieManagerSingle{
    static let sharedYHMovieManagerSingle = YHMovieManagerSingle()
    private init(){
        
    }
}


public class YHMovieManager: NSObject {
    
    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    var playerView:YHMovieView?
//    public class var SharedYHMovieManager : YHMovieManager {
//        struct Manager {
//            static var onceToken : dispatch_once_t = 0
//            static var instance : YHMovieManager? = nil
//        }
//        dispatch_once(&Manager.onceToken) {
//            Manager.instance = YHMovieManager()
//        }
//        return Manager.instance!
//    }
    
//    class YHMovieManagers {
//        static let SharedYHMovieManager: YHMovieManagers = {
//            let instance = YHMovieManagers()
//            // setup code
//            return instance
//        }()
//    }
    
 
    
    deinit{
        playerView?.playerItem?.removeObserver(self, forKeyPath: "status")
        playerView?.playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        
         NotificationCenter.default.removeObserver(self)
    }
 
    
    public func startAV(urlStr:String,frame:CGRect,goalView:UIView) -> Bool {
        
        let playerView = YHMovieView.init(frame: frame)
        playerView.playerItem = AVPlayerItem.init(url: NSURL.init(string: urlStr)! as URL)
        playerView.player = AVPlayer.init(playerItem: playerView.playerItem!)
        shareYHMovieManager.playerView = playerView
    
        // 监听status属性
        playerView.playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        //监听loadedTimeRanges属性
        playerView.playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
    
        //监听播放完成后
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object:  playerView.playerItem)
        
        //用player生成Layer
        let playerLayer=AVPlayerLayer(player:  playerView.player)
        playerLayer.frame = (playerView.frame)
        
        //图层填充
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        //需要把图层插入到最底层，不会影响其他的视图
        playerView.layer.insertSublayer(playerLayer, at: 0)
        
        goalView.addSubview(playerView)
        return true
    }
    
    
    /// 播放完之后
    func moviePlayDidEnd() {
        shareYHMovieManager.playerView?.stop()
    }
    
    
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let playerItem = object as? AVPlayerItem
        if keyPath == "status"{
            if playerItem?.status ==  AVPlayerItemStatus.readyToPlay {
                let duration = playerItem!.duration
                let currentTime = playerItem!.currentTime()
                let durationSeconds = duration.value / Int64(duration.timescale)
                let currentSeconds = currentTime.value / Int64(currentTime.timescale)
                let totalStr = convertTime(second: durationSeconds)
                let currentStr = convertTime(second: currentSeconds)
                
                shareYHMovieManager.playerView?.durationTimeLabel?.text = "\(currentStr) / \(totalStr)"
                
                monitoringPlayback(playerItem: playerItem!)

            }
            else if playerItem?.status ==  AVPlayerItemStatus.failed {
                print("播放失败")
            }
        }
        else if keyPath == "loadedTimeRanges"{
            let timeInterval = availableDuration()
            let duration = playerItem!.duration
            let totalDuration = CMTimeGetSeconds(duration)
            
            //缓存条
            shareYHMovieManager.playerView?.progressView?.setProgress(Float(timeInterval / totalDuration), animated: true)
        }
        else{
            //前面条件都不成立的时候保证继续监控
            super.observeValue(forKeyPath: keyPath, of: object, change: change , context: context)
        }
    }
    
    //秒转时间字符串
    public func convertTime(second:Int64) -> String {
        let date = NSDate.init(timeIntervalSinceReferenceDate: Double(second))
        let formate = DateFormatter.init()
        if second / 3600 >= 1 {
            formate.dateFormat = "HH:mm:ss"
        } else {
            formate.dateFormat = "mm:ss"
        }
        
        return formate.string(from: date as Date)
    }
    
    //换算成字符串
    func availableDuration() -> Double {
//        let loadedTimeRanges = YHMovieManager.SharedYHMovieManager.playerView?.player?.currentItem?.loadedTimeRanges

        let loadedTimeRanges = shareYHMovieManager.playerView?.player?.currentItem?.loadedTimeRanges
        
//        获取缓冲区域
        let timeRange = loadedTimeRanges?.first?.timeRangeValue
        
        let startSeconds = CMTimeGetSeconds(timeRange!.start)
        
        let durationSeconds = CMTimeGetSeconds(timeRange!.duration)
        
        return startSeconds + durationSeconds
        
    }
    
    //改变当前时间和进度条
    func monitoringPlayback(playerItem:AVPlayerItem) {
        _ =  shareYHMovieManager.playerView?.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: nil, using: { (time) in
            
            let duration = playerItem.duration
            let currentTime = playerItem.currentTime()
            let durationSeconds = duration.value / Int64(duration.timescale)
            let currentSeconds = currentTime.value / Int64(currentTime.timescale)
            let totalStr = self.convertTime(second: durationSeconds)
            let currentStr = self.convertTime(second: currentSeconds)
            
            shareYHMovieManager.playerView?.durationTimeLabel?.text = "\(currentStr) / \(totalStr)"
            shareYHMovieManager.playerView?.slider?.setValue(Float(currentSeconds ) / Float(durationSeconds) , animated: true)

            
//            YHMovieManager.SharedYHMovieManager.playerView?.durationTimeLabel?.text = "\(currentStr) / \(totalStr)"
//            YHMovieManager.SharedYHMovieManager.playerView?.slider?.setValue(Float(currentSeconds ) / Float(durationSeconds) , animated: true)
        })
    }
    
}

