//
//  ViewController.swift
//  YHMovieViewDemo
//
//  Created by srgroup on 16/5/12.
//  Copyright © 2016年 developeryh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let playView = YHMovieView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200))
//        playView.play()
        let model = YHMovieModel()
        model.urlStr = "http://download.3g.joy.cn/video/236/60236937/1451280942752_hd.mp4"
        playView.model = model
        
        self.view.addSubview(playView)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

