//
//  File.swift
//  
//
//  Created by Carey Zhang on 2020/8/10.
//

import Foundation
import CoreLocation
import UIKit

public class GPSManager: NSObject{
    let locationManager = CLLocationManager()
    public override init() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        if CLLocationManager.locationServicesEnabled(){
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                print("No access")
            case .authorizedAlways, .authorizedWhenInUse:
                print("Access")
            default:
                break
            }
        }
        else{
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingHeading()
        }
    }
    
    public func getLocation()->CLLocationCoordinate2D{
        guard let locVal:CLLocationCoordinate2D = locationManager.location?.coordinate else{
            return CLLocationCoordinate2D.init(latitude: 0, longitude: 0)
        }
        print("current location: \(locVal.latitude) \(locVal.longitude)")

        return locVal
    }
}
