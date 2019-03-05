//
//  GradientLineChartPresenter.swift
//  GradLineChart WatchKit Extension
//
//  Created by Prateek Sharma on 3/4/19.
//  Copyright © 2019 Prateek Sharma. All rights reserved.
//

import WatchKit
import Foundation

struct Result {
    var x: Double
    var y: Double
}

protocol LineChartDataSource: class {
    func numberOfPoints(forChartPresenter chartPresenter: GradientLineChartPresenter) -> Int
    func maximumResultValue(forChartPresenter chartPresenter: GradientLineChartPresenter) -> Result
    func resultForPoint(atIndex index: Int, forChartPresenter chartPresenter: GradientLineChartPresenter) -> Result
}

class GradientLineChartPresenter {
    
    weak var dataSource: LineChartDataSource?
    var lineWidth: CGFloat = 2
    var circleDiameter: CGFloat = 4
    
    weak private var graphWKImage: WKInterfaceImage?
    private var maxResult: Result?
    private var results = [Result]()
    
    func reload(for interfaceImage: WKInterfaceImage, size: CGSize) {
        clearOutGraph()
        
        guard let dataSource = dataSource  else { return }
        graphWKImage = interfaceImage
        
        let maxResultValue = dataSource.maximumResultValue(forChartPresenter: self)
        
        guard maxResultValue.x > 0 && maxResultValue.y > 0
        else { fatalError("Non-zero and Non-negative values required for Max-Result") }
        
        maxResult = maxResultValue
        getGraphPoints()
        drawGraph(ofSize: size)
    }
    
    private func clearOutGraph() {
        maxResult = nil
        results.removeAll()
        graphWKImage?.setImage(nil)
        graphWKImage = nil
    }
    
    private func getGraphPoints() {
        guard let dataSource = dataSource  else { return }
        
        let numberOfPoints = dataSource.numberOfPoints(forChartPresenter: self)
        guard numberOfPoints > 1, let maxResult = maxResult   else { return }
        
        for i in 0..<numberOfPoints {
            let result = dataSource.resultForPoint(atIndex: i, forChartPresenter: self)
            guard result.y <= maxResult.y, result.y >= 0,
                  result.x <= maxResult.x, result.x >= 0
            else { continue }
            results.append(result)
        }
    }
    
    private func createGraphLinesPath(rect: CGRect) -> UIBezierPath {
        var isFirstPoint = true
        let graphPath = UIBezierPath()
        for res in results {
            let xMultiplier = CGFloat(res.x / maxResult!.x)
            let yMultiplier = 1 - CGFloat(res.y / maxResult!.y)
            let graphPoint = CGPoint(x: (rect.size.width * xMultiplier) + rect.origin.x, y: (rect.size.height * yMultiplier) + rect.origin.y)

            if isFirstPoint {
                graphPath.move(to: graphPoint)
                isFirstPoint = false
            } else {
                graphPath.addLine(to: graphPoint)
            }
        }
        graphPath.lineWidth = lineWidth
        return graphPath
    }
    
    private func addGraphClipping(using graphLinePath: UIBezierPath, rect: CGRect) {
        guard !results.isEmpty,
              let clippingPath = graphLinePath.copy() as? UIBezierPath
        else { return }
        
        let xMultiplier = CGFloat(results.last!.x / maxResult!.x)
        let yMultiplier = 1 - CGFloat(results.last!.y / maxResult!.y)
        let endPoint = CGPoint(x: (rect.size.width * xMultiplier) + rect.origin.x, y: (rect.size.height * yMultiplier) + rect.origin.y)

        clippingPath.addLine(to: CGPoint(x: endPoint.x, y: rect.size.height))
        clippingPath.addLine(to: CGPoint(x: rect.origin.x, y: rect.size.height))
        clippingPath.close()
        clippingPath.addClip()
    }
    
    private func drawGradient(ofHeight height: CGFloat, inContext context: CGContext) {
        var maxYValue: Double = 0
        for res in results {
            maxYValue = max(res.y, maxYValue)
        }
        let startHeight = (height * (1 - CGFloat(maxYValue / maxResult!.y)))
        
        let colors = [UIColor.lightGray.cgColor, UIColor.clear.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: startHeight), end: CGPoint(x: 0, y: height), options: [])
    }
    
    private func drawGraph(ofSize size: CGSize) {
        guard maxResult != nil, results.count > 1  else { return }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let graphRect = CGRect(x: 3, y: 3, width: size.width - 6, height: size.height - 6)
        let graphLinePath = createGraphLinesPath(rect: graphRect)
        
        context.saveGState()
        addGraphClipping(using: graphLinePath, rect: graphRect)
        drawGradient(ofHeight: size.height, inContext: context)
        context.restoreGState()
        
        UIColor.blue.setStroke()
        graphLinePath.stroke()
//        circlePaths.forEach { $0.fill() }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        graphWKImage?.setImage(image)
    }
    
    
    
}

//        var circlePaths = [UIBezierPath]()
//        for point in graphPoints {
//            let xMultiplier = CGFloat(point.xScore / maxScores.x)
//            let yMultiplier = 1 - CGFloat(point.yScore / maxScores.y)
//            var graphPoint = CGPoint(x: size.width * xMultiplier, y: size.height * yMultiplier)
//
//            graphPoint.x -= circleDiameter / 2
//            graphPoint.y -= circleDiameter / 2
//            let circle = UIBezierPath(ovalIn: CGRect(origin: graphPoint, size: CGSize(width: circleDiameter, height: circleDiameter)))
//            UIColor.white.setFill()
//            circlePaths.append(circle)
//        }
