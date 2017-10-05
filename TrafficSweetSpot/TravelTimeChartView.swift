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
        DispatchQueue.main.async {
            if (self.lineChartView != nil) {
                self.lineChartView.notifyDataSetChanged()
            }
        }
    }

    func initData(_ data: LineChartData) {
        DispatchQueue.main.async {
            if (self.lineChartView != nil) {
                self.lineChartView.leftAxis.axisMinimum = 0
                self.lineChartView.rightAxis.axisMinimum = 0
                self.lineChartView.chartDescription?.text = ""
                self.lineChartView.noDataText = "No data yet"
                self.lineChartView.xAxis.valueFormatter = TravelTimeChartFormatter()
                self.lineChartView.xAxis.setLabelCount(5, force: true)
                self.lineChartView.data = data
            }
        }
    }
}
