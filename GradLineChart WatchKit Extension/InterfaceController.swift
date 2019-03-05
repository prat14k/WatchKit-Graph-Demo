//
//  InterfaceController.swift
//  GradLineChart WatchKit Extension
//
//  Created by Prateek Sharma on 3/4/19.
//  Copyright © 2019 Prateek Sharma. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var chartImageView: WKInterfaceImage!
    private let lineGraphPresenter = GradientLineChartPresenter()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        lineGraphPresenter.dataSource = self
        let size = min(contentFrame.height, contentFrame.width)
        lineGraphPresenter.reload(for: chartImageView, size: CGSize(width: size, height: size))
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}


extension InterfaceController: LineChartDataSource {
    
    func numberOfPoints(forChartPresenter chartPresenter: GradientLineChartPresenter) -> Int {
        return 6
    }
    
    func maximumResultValue(forChartPresenter chartPresenter: GradientLineChartPresenter) -> Result {
        return Result(x: 100, y: 100)
    }
    
    func resultForPoint(atIndex index: Int, forChartPresenter chartPresenter: GradientLineChartPresenter) -> Result {
        return Result(x: (100 / (6 - 1)) * Double(index), y: Double(arc4random_uniform(70)) + 20)
    }
    
}

