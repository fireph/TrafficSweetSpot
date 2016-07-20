//
//  StatusMenuController.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/19/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Cocoa
import Charts

class StatusMenuController: NSObject, PreferencesWindowDelegate {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var travelTime: NSMenuItem!
    @IBOutlet weak var lastTimestamp: NSMenuItem!
    @IBOutlet weak var travelTimeChartMenuItem: NSMenuItem!
    @IBOutlet weak var travelTimeChart: TravelTimeChartView!
    var aboutWindow: AboutWindow!
    var preferencesWindow: PreferencesWindow!

    let INTERVAL_TIME_IN_SECONDS = 300.0
    let THROW_AWAY_DATA_AFTER_MINUTES = 120.0

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
    let mapsAPI = MapsDistanceMatrixAPI()
    
    var routes : [Route] = []
    var routeTimestamps : [String] = []
    var routesSet : LineChartDataSet!
    var routesData : LineChartData!
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.template = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
        aboutWindow = AboutWindow()
        preferencesWindow = PreferencesWindow()
        preferencesWindow.delegate = self
        travelTimeChartMenuItem.view = travelTimeChart
        initChartData()
        updateTravelTime()
        let alarm = NSTimer.scheduledTimerWithTimeInterval(
            INTERVAL_TIME_IN_SECONDS,
            target: self,
            selector: #selector(StatusMenuController.updateTravelTime),
            userInfo: nil,
            repeats: true
        )
        NSRunLoop.mainRunLoop().addTimer(alarm, forMode: NSRunLoopCommonModes)
    }
    
    func updateTravelTime() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let apiKey = defaults.stringForKey("apiKey")
        let origin = defaults.stringForKey("origin")
        let dest = defaults.stringForKey("dest")
        if (apiKey == nil || origin == nil || dest == nil) {
            return;
        }
        mapsAPI.fetchTravelTime(apiKey!, origin: origin!, dest: dest!) { route in
            dispatch_async(dispatch_get_main_queue()) {
                self.travelTime.title = "Current travel time: \(route.durationString)"
                self.lastTimestamp.title = "Last fetched time: \(route.timestampString)"
            }
            self.statusMenu.itemChanged(self.travelTime)
            self.statusMenu.itemChanged(self.lastTimestamp)
            self.removeOldRoutesIfNeeded(route.timestamp)
            self.fillMissingRoutesIfNeeded(route.timestamp)
            self.appendRouteToSet(route)
        }
    }
    
    func appendRouteToSet(route: Route) {
        if (routesSet != nil && routesData != nil) {
            let index = self.routes.count
            self.routes.append(route)
            routeTimestamps.append(route.timestampString)
            routesSet.addEntry(ChartDataEntry(value: Double(route.duration)/60.0, xIndex: index))
            routesData.addXValue(route.timestampString)
            routesData.notifyDataChanged()
            travelTimeChart.update()
            statusMenu.itemChanged(travelTimeChartMenuItem)
        }
    }
    
    func removeOldRoutesIfNeeded(currentTimestamp: Double) {
        var firstTimestamp = routes.first?.timestamp
        if (firstTimestamp < (currentTimestamp - THROW_AWAY_DATA_AFTER_MINUTES*60 - 60*60)) {
            while routes.count > 0 && firstTimestamp < (currentTimestamp - THROW_AWAY_DATA_AFTER_MINUTES*60) {
                routes.removeFirst()
                firstTimestamp = routes.first?.timestamp
            }
            initChartData()
            travelTimeChart.update()
            statusMenu.itemChanged(travelTimeChartMenuItem)
        }
    }

    func fillMissingRoutesIfNeeded(currentTimestamp: Double) {
        if (self.routes.count == 0) {
            return;
        }
        var prevTime = self.routes.last!.timestamp
        if (prevTime <= currentTimestamp - (2 * INTERVAL_TIME_IN_SECONDS)) {
            while prevTime <= currentTimestamp - INTERVAL_TIME_IN_SECONDS {
                prevTime += INTERVAL_TIME_IN_SECONDS
                let route = Route(
                    duration: 0,
                    durationString: "0 min",
                    distance: 0,
                    distanceString: "0 mi",
                    timestamp: prevTime,
                    timestampString: getTimestampString(prevTime)
                )
                self.appendRouteToSet(route)
            }
        }
    }
    
    func initChartData() {
        routeTimestamps = []
        var yVals1 : [ChartDataEntry] = [ChartDataEntry]()
        for i in 0 ..< routes.count {
            yVals1.append(ChartDataEntry(value: Double(routes[i].duration)/60.0, xIndex: i))
            routeTimestamps.append(routes[i].timestampString)
        }
        routesSet = LineChartDataSet(yVals: yVals1, label: "Travel Time (min)")
        routesSet.axisDependency = .Left
        routesSet.setColor(NSUIColor.blueColor().colorWithAlphaComponent(1.0)) // our line's opacity is 50%
        routesSet.lineWidth = 2.0
        routesSet.drawFilledEnabled = true
        routesSet.fillColor = NSUIColor.cyanColor()
        routesSet.circleRadius = 0
        routesSet.highlightColor = NSUIColor.whiteColor()
        routesSet.drawValuesEnabled = false
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(routesSet)
        routesData = LineChartData(xVals: routeTimestamps, dataSets: dataSets)
        travelTimeChart.initData(routesData)
    }
    
    func preferencesDidUpdate() {
        routes = []
        initChartData()
        updateTravelTime()
    }

    @IBAction func aboutClicked(sender: AnyObject) {
        aboutWindow.showWindow(nil)
    }
    
    @IBAction func preferencesClicked(sender: AnyObject) {
        preferencesWindow.showWindow(nil)
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    func getTimestampString(timestamp: Double) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = dateFormatter.stringFromDate(NSDate(timeIntervalSinceReferenceDate: timestamp))
        return timeString
    }
}
