//
//  MapsDistanceMatrixAPI.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/19/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Route {
    var duration: Int
    var durationString: String
    var distance: Int
    var distanceString: String
    var timestamp: Double
    var timestampString: String
}

class MapsDistanceMatrixAPI {
    let BASE_URL = "https://maps.googleapis.com/maps/api/distancematrix/json"

    func fetchTravelTime(apiKey: String, origin: String, dest: String, success: (Route) -> Void) {
        let session = NSURLSession.sharedSession()
        // url-escape the query string we're passed
        let escapedOrigin = origin.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let escapedDest = dest.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let url = NSURL(string: "\(BASE_URL)?mode=driving&departure_time=now&key=\(apiKey)&units=imperial&origins=\(escapedOrigin!)&destinations=\(escapedDest!)")
        let task = session.dataTaskWithURL(url!) { data, response, err in
            // first check for a hard error
            if let error = err {
                NSLog("maps api error: \(error)")
            }
            
            // then check the response code
            if let httpResponse = response as? NSHTTPURLResponse {
                switch httpResponse.statusCode {
                case 200: // all good!
                    if let route = self.routeFromJSONData(data!) {
                        success(route)
                    }
                case 401: // unauthorized
                    NSLog("maps api returned an 'unauthorized' response. Did you set your API key?")
                default:
                    NSLog("maps api returned response: %d %@", httpResponse.statusCode, NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode))
                }
            }
        }
        task.resume()
    }
    
    func routeFromJSONData(data: NSData) -> Route? {
        let json = JSON(data: data)
        let durationJson = json["rows"][0]["elements"][0]["duration_in_traffic"]
        let distanceJson = json["rows"][0]["elements"][0]["distance"]
        if (durationJson == nil || distanceJson == nil) {
            return nil
        }
        let route = Route(
            duration: durationJson["value"].int!,
            durationString: durationJson["text"].string!,
            distance: distanceJson["value"].int!,
            distanceString: distanceJson["text"].string!,
            timestamp: getTimestamp(),
            timestampString: getTimestampString()
        )
        return route
    }
    
    func getTimestamp() -> Double {
        let timestamp = NSDate().timeIntervalSince1970
        return timestamp
    }
    
    func getTimestampString() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeString = dateFormatter.stringFromDate(NSDate())
        return timeString
    }
}
