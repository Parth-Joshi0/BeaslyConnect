//
//  LocationManager.swift
//  beastlyConnect
//
//  Created by Parth Joshi on 2026-01-10.
//
import SwiftUI
import MapKit
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var coordinate: CLLocationCoordinate2D? = nil
    @Published var status: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    var isAuthorized: Bool {
        status == .authorizedAlways || status == .authorizedWhenInUse
    }

    var showDeniedBanner: Bool {
        status == .denied || status == .restricted
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestOneShotLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if isAuthorized { manager.requestLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // keep silent for demo
    }
}
