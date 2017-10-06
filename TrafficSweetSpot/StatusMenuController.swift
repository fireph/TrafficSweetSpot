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
    let TIME_BETWEEN_NOTIFICATIONS = 4.0 * 60.0 * 60.0

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
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
    var lastNotificationTimestamp: Double?

    var routesSet : LineChartDataSet!
    var routesData : LineChartData!
    
    override func awakeFromNib() {
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        icon?.isTemplate = true // best for dark mode
        statusItem.image = icon
        statusItem.menu = statusMenu
        aboutWindow = AboutWindow()
        preferencesWindow = PreferencesWindow()
        updateWindow = UpdateWindow()
        preferencesWindow?.delegate = self
        travelTimeChartMenuItem.view = travelTimeChart
        initDefaults()
        initChartData(routes: [])
        updateTravelTime()
        let alarm = Timer.scheduledTimer(
            withTimeInterval: INTERVAL_TIME_IN_SECONDS,
            repeats: true,
            block: { (Timer) in
                self.updateTravelTime()
            }
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
            self.appendRouteToSet(route, cache: cache)
        }
    }
    
    func appendRouteToSet(_ route: Route, cache: Double) {
        if (routesSet != nil && routesData != nil) {
            let entry = ChartDataEntry(x: route.timestamp, y: Double(route.duration)/60.0)
            if (routesSet.entryCount > 0) {
                let notificationsEnabled = defaults?.string(forKey: "notificationsEnabled")?.toBool() ?? false
                let notificationsTime = Double((defaults?.string(forKey: "notificationsTime"))!) ?? -1.0
                let lastEntryTime = routesSet.entryForIndex(routesSet.entryCount - 1)?.y ?? entry.y
                if (notificationsEnabled
                    && entry.x - (lastNotificationTimestamp ?? 0.0) > TIME_BETWEEN_NOTIFICATIONS
                    && lastEntryTime > notificationsTime
                    && entry.y <= notificationsTime) {
                    lastNotificationTimestamp = entry.x
                    showNotification(subtitle: "Traffic has died down 😀", text: "Travel time is now: " + String(Int(entry.y)) + " minutes")
                }
            }
            if (routesSet.addEntry(entry)) {
                removeOldRoutesIfNeeded(route.timestamp, cache: cache)
                routesData.notifyDataChanged()
                travelTimeChart.update()
                statusMenu.itemChanged(travelTimeChartMenuItem)
            }
        }
    }
    
    func removeOldRoutesIfNeeded(_ currentTimestamp: Double, cache: Double) {
        var firstTimestamp = routesSet.entryForIndex(0)?.x
        let cacheTimeSeconds = cache*60.0*60.0
        while routesSet.entryCount > 0 && firstTimestamp < (currentTimestamp - cacheTimeSeconds) {
            if (routesSet.removeFirst()) {
                firstTimestamp = routesSet.entryForIndex(0)?.x
            } else {
                // Something went wrong, stop trying to remove entries from the set
                break
            }
        }
    }
    
    func initChartData(routes: [Route]) {
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
            routesSet.clear()
            travelTimeChart.update()
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
            withTimeInterval: CHECK_FOR_UPDATES_INTERVAL_DAYS*24.0*60.0*60.0,
            repeats: true,
            block: { (Timer) in
                self.checkForUpdate()
            }
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
        NSApplication.shared.terminate(self)
    }
    
    func getTimestampString(_ timestamp: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: timestamp))
        return timeString
    }
    
    func showNotification(subtitle: String, text: String) {
        let notification = NSUserNotification()
        notification.title = "TrafficSweetSpot"
        notification.subtitle = subtitle
        notification.informativeText = text
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
