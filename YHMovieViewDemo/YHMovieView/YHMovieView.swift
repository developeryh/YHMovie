//
//  YHMovieView.swift
//  YHMovieViewDemo
//
//  Created by srgroup on 16/5/12.
//  Copyright © 2016年 developeryh. All rights reserved.
//

import UIKit
import AVFoundation

/**
  播放视图的位置状态
 
 - Normal:          正常情况
 - FullScreen:      全屏
 - SummaryFill:     简易缩略,会损失部分画面，但不会变形
 -SummaryClip:
 */
public enum YHMovieViewLocationStates {
    case normal
    case fullScreen
    case summaryFill
    case summaryClip
}

/**
 *  YHMovieViewDelegate
 */
public protocol YHMovieViewDelegate {
    
    /**
     播放器状态发生变换时的回调
     
     - parameter status: 播放器状态：
     
     case Unknown
     case ReadyToPlay
     case Failed
     
     */
    func playerStatusChange(_ status:AVPlayerItemStatus)
    
    

}

/**
 *  YHMovieView,主类
 */
open class YHMovieView: UIView {
    
    var delegate:YHMovieViewDelegate?
    var player:AVPlayer?
    var playerItem:AVPlayerItem?
    var locationState:YHMovieViewLocationStates = YHMovieViewLocationStates.normal
   
    override open class var layerClass : AnyClass {
        return CAEAGLLayer.self
    }
    
    deinit{
        print("AVplayer 释放")
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.brown

        loadSubViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func loadSubViews() {
    
        self.addSubview(rippleView!)
        self.addSubview(toolView!)
        toolView?.addSubview(playBtn!)
        toolView?.addSubview(slider!)
        toolView?.addSubview(progressView!)
        toolView?.addSubview(durationTimeLabel!)
    }
    
    //拖动进度条
    func changePlayerValue(_ slide:UISlider) {
        let duration = self.playerItem!.duration
        let durationSeconds = duration.value / Int64(duration.timescale)
        

        let timeCM = CMTime.init(seconds: Double(slide.value) * Double(durationSeconds) , preferredTimescale: duration.timescale)
        self.player?.seek( to: timeCM, completionHandler: { (ret) in
            return true
        })

    }
    
    //播放/停止
    func playBtnClick(_ btn:UIButton) {
        
        if btn.isSelected == false {
            play()
        }
        else{
            stop()
        }
    }
    
    func play() {
        playBtn!.isSelected = true
        if self.player == nil {
            //初始化player，初始化后会加载缓存
            self.player = AVPlayer.init(playerItem: self.playerItem!)
            
            //用player生成Layer
            let playerLayer=AVPlayerLayer(player:  self.player)
            playerLayer.frame = (self.frame)
            
            let state:YHMovieViewLocationStates = (self.model?.locationState)!
            switch state {
            case YHMovieViewLocationStates.normal:
                print("1")
                //不变形，不超出(默认属性)
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            
            case YHMovieViewLocationStates.fullScreen:
                
                //不变形，不超出
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                
            case YHMovieViewLocationStates.summaryFill:
                
                //变形，不超出
                playerLayer.videoGravity = AVLayerVideoGravityResize
                
            case YHMovieViewLocationStates.summaryClip:
                
                //不变形，超出
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill


            }
         
            
            //需要把图层插入到最底层，不会影响其他的视图
            self.layer.insertSublayer(playerLayer, at: 0)
        }
        
        if self.playerItem?.currentTime() == self.playerItem?.duration {
            let time = CMTime.init(value: 0, timescale: self.playerItem!.currentTime().timescale)
            self.playerItem?.seek(to: time)
        }
        
        if self.playerItem?.status == AVPlayerItemStatus.failed || self.playerItem?.status == AVPlayerItemStatus.unknown{
            playBtn!.isSelected = false
        }
        
        self.player?.play()
    }
    
    func stop() {
        playBtn!.isSelected = false
        self.player?.pause()
    }
    
    

    //波纹视图
    lazy var rippleView:UIView? = {
        let rippleView = UIView.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        rippleView.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        rippleView.layer.cornerRadius = 50;
        rippleView.layer.masksToBounds = true;
        rippleView.alpha = 0;
        return rippleView
    
    }()
    
    //底部工具栏
    lazy var toolView:UIView? = {
        let view = UIView.init(frame: CGRect(x: 0, y: self.frame.size.height - 30, width: self.frame.size.width, height: 30))
        view.backgroundColor = UIColor.black
        view.alpha = 0.3
        return view
    }()
    
    //工具栏中的播放停止按钮
    lazy var playBtn:UIButton? = {
        let btn = UIButton.init(type: UIButtonType.custom)
        btn.setImage(UIImage.init(named: "stopPlay"), for: UIControlState())
        btn.setImage(UIImage.init(named: "startPlay"), for: UIControlState.selected)
        
        btn.addTarget(self, action: #selector(self.playBtnClick(_:)), for: UIControlEvents.touchUpInside)
        btn.frame = CGRect(x: 10, y: 5, width: 20, height: 20)
        return btn
    }()
    
    //缓存条
     lazy var progressView:UIProgressView? = {
        let view = UIProgressView.init(progressViewStyle: UIProgressViewStyle.default)
        view.frame = CGRect(x: 50, y: 14, width: self.frame.size.width - 100 - 50 , height: 2)
        return view
    }()
    
    //进度条
    lazy var slider:UISlider? = {
        let view = UISlider.init(frame: CGRect(x: 50, y: 10,  width: self.frame.size.width - 100 - 50 , height: 10))
        view.setThumbImage(UIImage.init(named: "yuan"), for: UIControlState())
        view.addTarget(self, action: #selector(YHMovieView.changePlayerValue(_:)), for: UIControlEvents.valueChanged)
        return view
    }()
    

    //总时间
    lazy var durationTimeLabel:UILabel? = {
        let label = UILabel.init(frame: CGRect(x: self.frame.size.width - 120, y: 9, width: 100, height: 12))
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.right
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()

    
    var model:YHMovieModel? {
        didSet{
            //初始化播放器资源
            self.playerItem = AVPlayerItem.init(url: URL.init(string: model!.urlStr)!)
            
            // 监听status属性
            self.playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            
            //监听loadedTimeRanges属性
            self.playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
            
            //监听播放完成后
            NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object:  self.playerItem)

        }
    }
    
//    public var player:AVPlayer? {
//        set{
//            let  avPlayer  = AVPlayerLayer.init(layer: self.layer)
//            avPlayer.player = player
//    
//        }
//        get{
//            let  avPlayer  = AVPlayerLayer.init(layer: self.layer)
//            return avPlayer.player
//        }
//    }

}


//MARK: - 手势
extension YHMovieView:UIGestureRecognizerDelegate{
    //点击
    func addTapGes() -> UITapGestureRecognizer{
        let tapGes = UITapGestureRecognizer.init(target: self, action: #selector(YHMovieView.tapGesEvent(_:)))
        tapGes.delegate = self
        return tapGes
    }
    
    //拖动
    func addPanGes() -> UIPanGestureRecognizer {
        let panGes = UIPanGestureRecognizer.init(target: self, action: #selector(YHMovieView.panGesEvent(_:)))
        panGes.delegate = self
        return panGes
    }
    
    //旋转
    func addRotationGes() -> UIRotationGestureRecognizer {
        let rotationGes = UIRotationGestureRecognizer.init(target: self, action: #selector(YHMovieView.rotationGesEvent(_:)))
        rotationGes.delegate = self
        return rotationGes;
    }
    
    //捏合
    func addPinchGes() -> UIPinchGestureRecognizer {
        let pinchGes = UIPinchGestureRecognizer.init(target: self, action: #selector(YHMovieView.pinchGesEvent(_:)))
        pinchGes.delegate = self
        return pinchGes
    }
    
    
    func tapGesEvent(_ ges:UITapGestureRecognizer) {
        print("打印tapGesEvent");
    }
    
    func panGesEvent(_ ges:UIPanGestureRecognizer) {
        print("打印panGesEvent");
        
        //在父视图中的坐标(原先为0,也就是移动了多少，坐标就是多少)
        let translation = ges.translation(in: self.superview)
        
        //确定中心点(本身center + 父视图坐标 = 父视图中的center坐标)
        ges.view?.center = CGPoint(x: ges.view!.center.x + translation.x,
                                       y: ges.view!.center.y + translation.y);
        
        //在父视图中的坐标重新置0
        ges.setTranslation(CGPoint.zero, in: self.superview)
        
        
        print("translation\(translation),center\(ges.view?.center)")
        
        //手势结束后处理（减速运动）
        if ges.state == UIGestureRecognizerState.ended {
            //在父视图中的速度矢量
            let velocity = ges.velocity(in: self.superview)
            
            //开平方根(速度标量)
            let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
            
            //速度标量除一定的系数
            let slideFactor = 0.1 * magnitude * 0.005
            
            //最后的点
            var finalPoint = CGPoint(x: ges.view!.center.x + (velocity.x * slideFactor),
                                         y: ges.view!.center.y + (velocity.y * slideFactor));
            
            //取较小数(保证中心点不超出屏幕)
            finalPoint.x =  min(max(finalPoint.x, 0), self.superview!.bounds.size.width)
            finalPoint.y =  min(max(finalPoint.y, 0), self.superview!.bounds.size.height)
            
            UIView.animate(withDuration: Double(slideFactor) * 2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
                ges.view!.center = finalPoint
                }, completion: nil)
            
        }
        
    }
    
    func rotationGesEvent(_ ges:UIRotationGestureRecognizer) {
        print("打印rotationGesEvent");
        
        ges.view!.transform = ges.view!.transform.rotated(by: ges.rotation);
        ges.rotation = 0.0;
    }
    
    func pinchGesEvent(_ ges:UIPinchGestureRecognizer) {
        print("打印pinchGesEvent");
        let scale = ges.scale
        
        //在已缩放大小基础下进行累加变化；区别于：使用CGAffineTransformMakeScale 方法就是在原大小基础下进行变化
        ges.view!.transform = ges.view!.transform.scaledBy(x: scale, y: scale);
        
        //重置scale
        ges.scale = 1.0;
    }

    
    //实现该协议，并返回true 可以让继承该协议的手势并行
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

//MARK: - 触摸事件
extension YHMovieView{
    //开始触摸(点击波纹效果)
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
    
        
        let touch = touches.first
        let location = touch?.location(in: self)
        //显示波纹
        self.rippleView?.alpha = 1
        
        rippleView?.center = location!
        rippleView?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(withDuration: 0.1, animations: {
            self.rippleView?.alpha = 1
        }) 
        
        UIView.animate(withDuration: 0.7, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.rippleView?.transform = CGAffineTransform(scaleX: 1,y: 1)
            self.rippleView?.alpha = 0
        }) { (finshed) in
            self.rippleView?.alpha = 0
        }
    }
    
    
    func changeToolViewState(_ hideOrShow:Bool) {
        
    }
    
    
}

//MARK: - 监控（KVO,通知，定时器）
extension YHMovieView{
    
    //播放结束
    func moviePlayDidEnd() {
        self.stop()
    }
    
    //KVO
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let playerItem = object as? AVPlayerItem
        if keyPath == "status"{
            delegate?.playerStatusChange((playerItem?.status)!)
            if playerItem?.status ==  AVPlayerItemStatus.readyToPlay {
                let duration = playerItem!.duration
                let currentTime = playerItem!.currentTime()
                let durationSeconds = duration.value / Int64(duration.timescale)
                let currentSeconds = currentTime.value / Int64(currentTime.timescale)
                let totalStr = convertTime(durationSeconds)
                let currentStr = convertTime(currentSeconds)
                
                self.durationTimeLabel?.text = "\(currentStr) / \(totalStr)"
                
                monitoringPlayback(playerItem!)
                
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
            self.progressView?.setProgress(Float(timeInterval / totalDuration), animated: true)
        }
        else{
            //前面条件都不成立的时候保证继续监控
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    //秒转时间字符串
    public func convertTime(_ second:Int64) -> String {
        let date = Date.init(timeIntervalSinceReferenceDate: Double(second))
        let formate = DateFormatter.init()
        if second / 3600 >= 1 {
            formate.dateFormat = "HH:mm:ss"
        } else {
            formate.dateFormat = "mm:ss"
        }
        
        return formate.string(from: date)
    }
    
    //换算成字符串
    func availableDuration() -> Double {
        let loadedTimeRanges = self.player?.currentItem?.loadedTimeRanges
        
        //获取缓冲区域
        let timeRange = loadedTimeRanges?.first?.timeRangeValue
        
        let startSeconds = CMTimeGetSeconds(timeRange!.start)
        
        let durationSeconds = CMTimeGetSeconds(timeRange!.duration)
        
        return startSeconds + durationSeconds
        
    }
    
    //改变当前时间和进度条(定时器)
    func monitoringPlayback(_ playerItem:AVPlayerItem) {
        _ =  self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: nil, using: { (time) in
            
            let duration = playerItem.duration
            let currentTime = playerItem.currentTime()
            let durationSeconds = duration.value / Int64(duration.timescale)
            let currentSeconds = currentTime.value / Int64(currentTime.timescale)
            let totalStr = self.convertTime(durationSeconds)
            let currentStr = self.convertTime(currentSeconds)
            
            self.durationTimeLabel?.text = "\(currentStr) / \(totalStr)"
            self.slider?.setValue(Float(currentSeconds ) / Float(durationSeconds) , animated: true)
        })
    }
    
}



