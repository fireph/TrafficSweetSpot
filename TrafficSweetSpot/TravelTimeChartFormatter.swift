//
//  TravelTimeChartFormatter.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 10/5/17.
//  Copyright © 2017 Freddie Meyer. All rights reserved.
//

import Charts

class TravelTimeChartFormatter: NSObject, IAxisValueFormatter {

    public func stringForValue(_ value: Double, axis: Charts.AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }
}
