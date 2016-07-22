//
//  VersionChecker.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/21/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Foundation
import SwiftyJSON

class VersionChecker {
    func isAppUpdatedToNewestVersion(success: (Bool) -> Void) {
        let session = NSURLSession.sharedSession()
        let url = NSURL(string: "https://api.github.com/repos/DungFu/TrafficSweetSpot/releases/latest")
        let task = session.dataTaskWithURL(url!) { data, response, err in
            // first check for a hard error
            if let error = err {
                NSLog("github api error: \(error)")
            }
            
            // then check the response code
            if let httpResponse = response as? NSHTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: // all good!
                    if let newestVersion : String = self.newestVersionFromJSONData(data!) {
                        let newestVersionParsed = String(newestVersion.characters.dropFirst())
                        let currentVersion : String = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
                        let isNewestVersion = (newestVersionParsed == currentVersion)
                        success(isNewestVersion)
                    }
                default:
                    NSLog("github api returned response: %d %@", httpResponse.statusCode, NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode))
                }
            }
        }
        task.resume()
    }
    
    func newestVersionFromJSONData(data: NSData) -> String? {
        let json = JSON(data: data)
        return json["tag_name"].string!
    }
}