# TrafficSweetSpot

This is simple Mac status bar app that can give driving times between two places. It will track the driving time in a graph so that you can see the historical data for your route. I use it to track my commute and know the best time to leave the office! :)

You'll need a Google Maps API key for the distance matrix API for this app to work. You can get at API key here: https://developers.google.com/maps/documentation/distance-matrix/

The starting location and ending location can be in any format that Google can recognize. See examples:
```
1600 Amphitheatre Pkwy, Mountain View, CA
1 Facebook Way, Menlo Park, CA 94025
```

![TrafficSweetSpot Context Menu](https://i.imgur.com/MWtODi1.png)

![TrafficSweetSpot Settings Screen](https://i.imgur.com/7MRI8Da.png)

If you would like to build yourself:
1. checkout the repository
2. run `carthage update --platform macOS` in repository folder
3. open in Xcode
4. build :)
