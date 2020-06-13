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
    func isAppUpdatedToNewestVersion(_ success: @escaping (Bool) -> Void) {
        let session = URLSession.shared
        let url = URL(string: "https://api.github.com/repos/fireph/TrafficSweetSpot/releases/latest")
        let task = session.dataTask(with: url!, completionHandler: { data, response, err in
            // first check for a hard error
            if let error = err {
                NSLog("github api error: \(error)")
            }
            
            // then check the response code
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: // all good!
                    if let newestVersion : String = self.newestVersionFromJSONData(data!) {
                        let newestVersionParsed = String(newestVersion.characters.dropFirst())
                        let currentVersion : String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
                        let isNewestVersion = (newestVersionParsed == currentVersion)
                        success(isNewestVersion)
                    }
                default:
                    NSLog("github api returned response: %d %@", httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                }
            }
        }) 
        task.resume()
    }
    
    func newestVersionFromJSONData(_ data: Data) -> String? {
        let json = JSON(data: data)
        return json["tag_name"].string!
    }
}
