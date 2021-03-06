//
//  OnRunVC.swift
//  Treads
//
//  Created by Massimiliano on 24/04/2019.
//  Copyright © 2019 Massimiliano Bonafede. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import RealmSwift

class CurrentRunVC: LocationVC {
    
    //MARK: - Outlets
    
    @IBOutlet weak var swipeBGimageView: UIImageView!    
    @IBOutlet weak var sliderImageView: UIImageView!
    @IBOutlet weak var durationLbl: UILabel!
    @IBOutlet weak var paceLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var pauseBtn: UIButton!
    
    //MARK: - Properties
    
    fileprivate var startLocation: CLLocation!
    fileprivate var lastLocation: CLLocation!
    fileprivate var runDistance = 0.0
    fileprivate var counter = 0
    fileprivate var timer = Timer()
    fileprivate var pace = 0
    fileprivate var coordinateLocations = List<Location>()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(endRunSwiped(sender:)))
        sliderImageView.addGestureRecognizer(swipeGesture)
        sliderImageView.isUserInteractionEnabled = true
        swipeGesture.delegate = self as? UIGestureRecognizerDelegate
        //  Run.addRUnToReal(pace: pace, distance: runDistance, duration: counter, locations: coordinateLocations)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        manager?.delegate = self
        manager?.distanceFilter = 10
        startRun()
    }
    
    //MARK: - Methods
    
    func startRun() {
        manager?.startUpdatingLocation()
        startTimer()
        pauseBtn.setImage(#imageLiteral(resourceName: "pauseButton"), for: .normal)
    }
    
    func endRun() {
        manager?.startUpdatingLocation()
        // add our object to Realm
        pauseRun()
        Run.addRUnToReal(pace: pace, distance: runDistance, duration: counter, locations: coordinateLocations)
        //print("coooordinate\(coordinateLocations.first)")
    }
    
    func pauseRun() {
        startLocation = nil
        lastLocation = nil
        timer.invalidate()
        manager?.stopUpdatingLocation()
        pauseBtn.setImage(#imageLiteral(resourceName: "resumeButton"), for: .normal)
    }
    
    func startTimer() {
        durationLbl.text = counter.formatTimeDurationToString()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    func calculatePace(time seconds: Int, miles: Double) -> String {
        pace = Int(Double(seconds) / miles)
        return pace.formatTimeDurationToString()
    }
    
    //MARK: - Actions
    
    @objc func updateCounter() {
        counter += 1
        durationLbl.text = counter.formatTimeDurationToString()
    }
    
    @objc func endRunSwiped(sender: UIPanGestureRecognizer){
        let minAdjust: CGFloat = 80
        let maxAdjust: CGFloat = 128
        if let sliderView = sender.view {
            if sender.state == UIGestureRecognizer.State.began || sender.state == UIGestureRecognizer.State.changed{
                let translation = sender.translation(in: self.view)
                if sliderImageView.center.x >= (swipeBGimageView.center.x - minAdjust) && sliderImageView.center.x <= (swipeBGimageView.center.x + maxAdjust){
                    sliderView.center.x = sliderView.center.x + translation.x
                } else if sliderView.center.x >= (swipeBGimageView.center.x + maxAdjust){
                    sliderView.center.x = swipeBGimageView.center.x + maxAdjust
                    // End Run Code goes here
                    endRun()
                    dismiss(animated: true, completion: nil)
                } else {
                    sliderView.center.x = swipeBGimageView.center.x - minAdjust
                }
                
                sender.setTranslation(CGPoint.zero, in: self.view)
            } else if sender.state == UIGestureRecognizer.State.ended {
                UIView.animate(withDuration: 0.1) {
                    sliderView.center.x = self.swipeBGimageView.center.x - minAdjust
                }
            }
        }
    }
    
    @IBAction func pauseBtnPressed(_ sender: Any) {
        if timer.isValid {
            pauseRun()
        } else {
            startRun()
        }
        
    }
}

//MARK: - CLLocationManagerDelegate

extension CurrentRunVC: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            checkLocationAuthStatus()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if startLocation == nil {
            startLocation = locations.first
        } else if let locations = locations.last {
            runDistance += lastLocation.distance(from: locations)
            
            let newLocation = Location(latitude: Double(lastLocation.coordinate.latitude), longitude: Double(lastLocation.coordinate.longitude))
            print("newww location\(newLocation)")
            coordinateLocations.insert(newLocation, at: 0)
            distanceLbl.text = "\(runDistance.metersToMiles(places: 2))"//for converted km to miles
            if counter > 0 && runDistance > 0 {
                paceLbl.text = calculatePace(time: counter, miles: runDistance.metersToMiles(places: 2))
            }
        }
        lastLocation = locations.last
    }
}
