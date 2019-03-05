//
//  GradientLineChart.swift
//  GradLineChart WatchKit Extension
//
//  Created by Prateek Sharma on 3/4/19.
//  Copyright © 2019 Prateek Sharma. All rights reserved.
//

import WatchKit
import Foundation

typealias ScorePair = (x: Double, y: Double)

protocol LineChartDataSource: class {
    func numberOfPoints(forChartImage chartImage: GradientLineChart) -> Int
    func maximumXYValues(forChartImage chartImage: GradientLineChart) -> ScorePair
    func scoreForPoint(atIndex index: Int, forChartImage chartImage: GradientLineChart) -> Double
}

class GradientLineChart {
    
    weak var dataSource: LineChartDataSource?
    weak private var graphWKImage: WKInterfaceImage?
    
    private var maxScores: ScorePair?
    private let lineWidth: CGFloat = 2
    private let circleDiameter: CGFloat = 4
    private var graphPoints = [GraphPoint]()
    
    func reload(for interfaceImage: WKInterfaceImage, size: CGSize) {
        graphWKImage = interfaceImage
        clearOutGraph()
        guard let dataSource = dataSource
        else { return }
        
        let maxValues = dataSource.maximumXYValues(forChartImage: self)
        
        guard maxValues.x > 0 && maxValues.y > 0
        else { fatalError("Non-zero and Non-negative values required for graph Maximum Axis") }
        
        maxScores = maxValues
        getGraphPoints()
        drawGraph(ofSize: size)
    }
    
    private func clearOutGraph() {
        maxScores = nil
        graphPoints.removeAll()
        graphWKImage?.setImage(nil)
    }
    
    private func getGraphPoints() {
        guard let dataSource = dataSource  else { return }
        
        let numberOfPoints = dataSource.numberOfPoints(forChartImage: self)
        guard numberOfPoints > 1, let maxScores = maxScores   else { return }
        
        for i in 0..<numberOfPoints {
            let yScore = dataSource.scoreForPoint(atIndex: i, forChartImage: self)
            guard yScore <= maxScores.y, yScore >= 0
            else { continue }
            graphPoints.append(GraphPoint(xScore: (maxScores.x / Double(numberOfPoints - 1)) * Double(i), yScore: yScore))
        }
    }
    
    private func drawGraph(ofSize size: CGSize) {
        guard let maxScores = maxScores, graphPoints.count > 1  else { return }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        var startPoint: CGPoint?
        var endPoint: CGPoint?

        let graphPath = UIBezierPath()
        var maxPoint = CGPoint(x: 0, y: size.height)
        for point in graphPoints {
            let xMultiplier = CGFloat(point.xScore / maxScores.x)
            let yMultiplier = 1 - CGFloat(point.yScore / maxScores.y)
            let graphPoint = CGPoint(x: size.width * xMultiplier, y: size.height * yMultiplier)
            if startPoint == nil {
                graphPath.move(to: graphPoint)
                startPoint = graphPoint
            } else {
                graphPath.addLine(to: graphPoint)
            }
            maxPoint.y = min(graphPoint.y, maxPoint.y)
            endPoint = graphPoint
        }
        UIColor.blue.setStroke()
        graphPath.lineWidth = lineWidth
        
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
        context.saveGState()
        
        let clippingPath = graphPath.copy() as! UIBezierPath
        clippingPath.addLine(to: CGPoint(x: (endPoint?.x ?? 0), y: size.height))
        clippingPath.addLine(to: CGPoint(x: 0, y: size.height))
        clippingPath.close()
        
        //4 - add the clipping path to the context
        clippingPath.addClip()
        
        let colors = [UIColor.gray.cgColor, UIColor.clear.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)!
        context.drawLinearGradient(gradient, start: maxPoint, end: CGPoint(x: 0, y: size.height), options: [])
       context.restoreGState()
        
        graphPath.stroke()
//        circlePaths.forEach { $0.fill() }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        graphWKImage?.setImage(image)
    }
    
}


struct GraphPoint {
    var xScore: Double
    var yScore: Double
}
