//
//  StatusMenuController.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/19/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Cocoa
import Charts
import SwiftyJSON
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


extension String {
    func toBool() -> Bool? {
        switch self {
        case "True", "true", "yes", "1":
            return true
        case "False", "false", "no", "0":
            return false
        default:
            return nil
        }
    }
}

class StatusMenuController: NSObject, PreferencesWindowDelegate {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var travelTime: NSMenuItem!
    @IBOutlet weak var lastTimestamp: NSMenuItem!
    @IBOutlet weak var travelTimeChartMenuItem: NSMenuItem!
    @IBOutlet weak var travelTimeChart: TravelTimeChartView!
    var aboutWindow: AboutWindow?
    var preferencesWindow: PreferencesWindow?
    var updateWindow: UpdateWindow?

    let CHECK_FOR_UPDATES_INTERVAL_DAYS = 1.0
    let INTERVAL_TIME_IN_SECONDS = 300.0
    let THROW_AWAY_INTERVAL_MIN = 60.0

    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    let mapsAPI = MapsDistanceMatrixAPI()
    let versionChecker = VersionChecker()
    
    // defaults
    var defaults : UserDefaults?
    var apiKey : String?
    var origin : String?
    var dest : String?
    var cacheString : String?
    var checkForUpdates : Bool = true
    
    var checkForUpdatesTimer : Timer?

    var routes : [Route] = []
    var routesSet : LineChartDataSet!
    var routesData : LineChartData!
    
    override func awakeFromNib() {
        let icon = NSImage(named: "statusIcon")
        icon?.isTemplate = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
        aboutWindow = AboutWindow()
        preferencesWindow = PreferencesWindow()
        updateWindow = UpdateWindow()
        preferencesWindow?.delegate = self
        travelTimeChartMenuItem.view = travelTimeChart
        initDefaults()
        initChartData()
        updateTravelTime()
        let alarm = Timer.scheduledTimer(
            timeInterval: INTERVAL_TIME_IN_SECONDS,
            target: self,
            selector: #selector(StatusMenuController.updateTravelTime),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(alarm, forMode: RunLoopMode.commonModes)
    }
    
    func checkForUpdate() {
        versionChecker.isAppUpdatedToNewestVersion() { isUpdated in
            if (!isUpdated) {
                DispatchQueue.main.async {
                    self.updateWindow?.showWindow(nil)
                }
            }
        }
    }
    
    func initDefaults() {
        defaults = UserDefaults.standard
        apiKey = defaults?.string(forKey: "apiKey")
        origin = defaults?.string(forKey: "origin")
        dest = defaults?.string(forKey: "dest")
        cacheString = defaults?.string(forKey: "cache")
        refreshUpdateDefault()
    }
    
    func getCacheSizeFromString(_ cacheString: String) -> Double {
        switch cacheString {
            case "3 hours":
                return 3.0
            case "6 hours":
                return 6.0
            case "12 hours":
                return 12.0
            case "24 hours":
                return 24.0
            default:
                return 6.0
        }
    }
    
    func updateTravelTime() {
        if (apiKey == nil || origin == nil || dest == nil || cacheString == nil) {
            return;
        }
        let cache = getCacheSizeFromString(cacheString!)
        mapsAPI.fetchTravelTime(apiKey!, origin: origin!, dest: dest!) { route in
            DispatchQueue.main.async {
                self.travelTime.title = "Current travel time: \(route.durationString)"
                self.lastTimestamp.title = "Last fetched time: \(route.timestampString)"
            }
            self.statusMenu.itemChanged(self.travelTime)
            self.statusMenu.itemChanged(self.lastTimestamp)
            self.removeOldRoutesIfNeeded(route.timestamp, cache: cache)
            self.appendRouteToSet(route)
        }
    }
    
    func appendRouteToSet(_ route: Route) {
        if (routesSet != nil && routesData != nil) {
            self.routes.append(route)
            let entry = ChartDataEntry(x: route.timestamp, y: Double(route.duration)/60.0)
            let entryAdded = routesSet.addEntry(entry)
            if (entryAdded) {
                routesData.notifyDataChanged()
                travelTimeChart.update()
                statusMenu.itemChanged(travelTimeChartMenuItem)
            }
        }
    }
    
    func removeOldRoutesIfNeeded(_ currentTimestamp: Double, cache: Double) {
        var firstTimestamp = routes.first?.timestamp
        let cacheTimeSeconds = cache*60.0*60.0
        let throwAwayIntervalSeconds = THROW_AWAY_INTERVAL_MIN*60.0
        if (firstTimestamp < (currentTimestamp - cacheTimeSeconds - throwAwayIntervalSeconds)) {
            while routes.count > 0 && firstTimestamp < (currentTimestamp - cacheTimeSeconds) {
                routes.removeFirst()
                firstTimestamp = routes.first?.timestamp
            }
            initChartData()
            travelTimeChart.update()
            statusMenu.itemChanged(travelTimeChartMenuItem)
        }
    }
    
    func initChartData() {
        var routeValues : [ChartDataEntry] = [ChartDataEntry]()
        for i in 0 ..< routes.count {
            routeValues.append(ChartDataEntry(x: routes[i].timestamp, y: Double(routes[i].duration)/60.0))
        }
        routesSet = LineChartDataSet(values: routeValues, label: "Travel Time (min)")
        routesSet.axisDependency = .left
        routesSet.setColor(NSUIColor.blue.withAlphaComponent(1.0))
        routesSet.lineWidth = 2.0
        routesSet.drawFilledEnabled = true
        routesSet.fillColor = NSUIColor.cyan
        routesSet.circleRadius = 0
        routesSet.highlightColor = NSUIColor.white
        routesSet.drawValuesEnabled = false
        var dataSets : [LineChartDataSet] = [LineChartDataSet]()
        dataSets.append(routesSet)
        routesData = LineChartData(dataSets: dataSets)
        travelTimeChart.initData(routesData)
    }
    
    func preferencesDidUpdate() {
        let apiKeyNew = defaults?.string(forKey: "apiKey")
        let originNew = defaults?.string(forKey: "origin")
        let destNew = defaults?.string(forKey: "dest")
        let shouldResetData = (apiKeyNew != apiKey || originNew != origin || destNew != dest)
        apiKey = apiKeyNew
        origin = originNew
        dest = destNew
        cacheString = defaults?.string(forKey: "cache")
        if (shouldResetData) {
            routes = []
            initChartData()
            updateTravelTime()
        }
        refreshUpdateDefault()
    }
    
    func refreshUpdateDefault() {
        if let checkForUpdatesTemp : Bool = defaults?.string(forKey: "checkForUpdates")?.toBool() {
            checkForUpdates = checkForUpdatesTemp
        } else {
            checkForUpdates = true
        }
        if (checkForUpdates && checkForUpdatesTimer == nil) {
            startUpdateCheckTimer()
        } else if (!checkForUpdates && checkForUpdatesTimer != nil) {
            stopUpdateCheckTimer()
        }
    }
    
    func startUpdateCheckTimer() {
        checkForUpdate()
        checkForUpdatesTimer?.invalidate()
        checkForUpdatesTimer = Timer.scheduledTimer(
            timeInterval: CHECK_FOR_UPDATES_INTERVAL_DAYS*24.0*60.0*60.0,
            target: self,
            selector: #selector(StatusMenuController.checkForUpdate),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(checkForUpdatesTimer!, forMode: RunLoopMode.commonModes)
    }
    
    func stopUpdateCheckTimer() {
        checkForUpdatesTimer?.invalidate()
        checkForUpdatesTimer = nil
    }

    @IBAction func aboutClicked(_ sender: AnyObject) {
        aboutWindow?.showWindow(nil)
    }
    
    @IBAction func preferencesClicked(_ sender: AnyObject) {
        preferencesWindow?.showWindow(nil)
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
    
    func getTimestampString(_ timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: timestamp))
        return timeString
    }
}
