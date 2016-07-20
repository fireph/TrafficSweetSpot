//
//  TravelTimeChartView.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/19/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Cocoa
import Charts

class TravelTimeChartView: NSView {
    @IBOutlet weak var lineChartView: LineChartView!
    
    func update() {
        dispatch_async(dispatch_get_main_queue()) {
            if (self.lineChartView != nil) {
                self.lineChartView.notifyDataSetChanged()
            }
        }
    }

    func initData(data: LineChartData) {
        dispatch_async(dispatch_get_main_queue()) {
            if (self.lineChartView != nil) {
                self.lineChartView.leftAxis.axisMinValue = 0
                self.lineChartView.rightAxis.axisMinValue = 0
                self.lineChartView.descriptionText = ""
                self.lineChartView.noDataText = "No data yet"
                self.lineChartView.data = data
            }
        }
    }
}
