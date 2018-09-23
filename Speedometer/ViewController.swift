//
//  ViewController.swift
//  Speedometer
//
//  Created by mini on 23/02/2016.
//  Copyright © 2016 Digital Confusion. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var Map: MKMapView!
    @IBOutlet weak var DistanceTravelled: UILabel!
    @IBOutlet weak var NoLocations: UILabel!
    @IBOutlet weak var LabelTimer: UILabel!
    @IBOutlet weak var LabelAltitude: UILabel!
    @IBOutlet weak var Speed: UILabel!
    @IBOutlet weak var MaxSpeedLabel: UILabel!
    @IBOutlet weak var AltimetersLabel: UILabel!
    
    
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var traveledDistance: Double = 0
    var MaxSpeed: Double = 0
    var totalAltimeters: Double = 0
    var startAltitude: Double = 0
    var manager: CLLocationManager!
    var myLocations: [CLLocation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.activityType = CLActivityType.fitness
        manager.startUpdatingLocation()
        manager.requestAlwaysAuthorization()
        Map.delegate = self
        Map.mapType = MKMapType.standard
        Map.showsUserLocation = true
        
        
        let aSelector : Selector = #selector(ViewController.updateTime)
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: aSelector, userInfo: nil, repeats: true)
        
    }
    
    var player : AVAudioPlayer! = nil
    var audio2: AVAudioPlayer = AVAudioPlayer()
    var backMusic: AVAudioPlayer!
    
    @IBAction func PlayBycicleBell(_ sender: UIButton) {
        
        setSessionPlayerOn()
        backMusic = setupAudioPlayerWithFile("Bike-bell-sound", type: "mp3")
        setSystemVolume(1.0)
        //backMusic.volume = 1.0
        backMusic.play()
        setSessionPlayerOff()
        setSystemVolume(0.5)
    }
    
    
    func setSessionPlayerOn()
    {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch _ {
        }
    }
    func setSessionPlayerOff()
    {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch _ {
        }
    }
    
    
    
    func setSystemVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        
        for view in volumeView.subviews {
            if (NSStringFromClass(view.classForCoder) == "MPVolumeSlider") {
                let slider = view as! UISlider
                //slider.setValue(volume, animated: false)
                slider.value = volume
                slider.isHidden = true
            }
        }
    }
    
    
    func setupAudioPlayerWithFile(_ file:NSString, type:NSString) -> AVAudioPlayer
    {
        let path = Bundle.main.path(forResource: file as String, ofType: type as String)
        let url = URL(fileURLWithPath: path!)
        var audioPlayer:AVAudioPlayer?
        
        do
        {
            try audioPlayer = AVAudioPlayer(contentsOf: url)
        } catch {
            print("NO AUDIO PLAYER")
        }
        
        return audioPlayer!
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if startLocation == nil
        {
            startLocation = locations.first! as CLLocation
            startAltitude = startLocation.altitude
            Speed.text = "--.- km/h"
        }
        else
        {
            let lastLocation = locations.last! as CLLocation
            let distance = startLocation.distance(from: lastLocation)
            
            if startLocation.altitude < lastLocation.altitude {
                totalAltimeters += lastLocation.altitude - startLocation.altitude
            }
            let altimeters = lastLocation.altitude
            startLocation = lastLocation
            traveledDistance += distance
            
            
            
            AltimetersLabel.text = String (ceil(totalAltimeters)) + " m"
            
            // Speed label
            if lastLocation.speed * 3.6 > 0 {
                let numberOfPlaces = 2.0
                let multiplier = pow(10.0, numberOfPlaces)
                let speed = round(lastLocation.speed * 3.6 * multiplier) / multiplier
                Speed.text = String(speed) + " km/h"
            }
            else {
                Speed.text = "0.0 km/h"
            }
            
            LabelAltitude.text = String(ceil(lastLocation.altitude)) + " m"
            
            if traveledDistance > 1000 {
                let numberOfPlaces = 2.0
                let multiplier = pow(10.0, numberOfPlaces)
                let distance = (round(traveledDistance * multiplier) / multiplier) / 1000
                DistanceTravelled.text = String(distance) + " km"
            }
            else {
                DistanceTravelled.text = String(ceil(traveledDistance)) + " m" //"\(afstand) m"
            }
            
            
            if lastLocation.speed >= MaxSpeed {
                MaxSpeed = lastLocation.speed
            }
            MaxSpeedLabel.text = String(ceil(MaxSpeed * 3.6)) + " km/h"

        }
        
        
        
        myLocations.append(locations[0])
        
        let spanX = 0.005
        let spanY = 0.005
        let newRegion = MKCoordinateRegion(center: Map.userLocation.coordinate, span: MKCoordinateSpanMake(spanX, spanY))
        Map.setRegion(newRegion, animated: true)
        
        if (myLocations.count > 1){
            let sourceIndex = myLocations.count - 1
            let destinationIndex = myLocations.count - 2
            
            let c1 = myLocations[sourceIndex].coordinate
            let c2 = myLocations[destinationIndex].coordinate
            var a = [c1, c2]
            let polyline = MKPolyline(coordinates: &a, count: a.count)
            Map.add(polyline)
            
        }
    }
    
    
    @IBAction func StartTimer(_ sender: UIButton) {
        startTime = Date.timeIntervalSinceReferenceDate
    }
    
    @IBAction func PauseTimer(_ sender: UIButton) {
        
    }
    
    func mapView(_ mapView: MKMapView!, rendererFor overlay: MKOverlay!) -> MKOverlayRenderer! {
        
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.gray
            polylineRenderer.lineWidth = 3
            return polylineRenderer
        }
        return nil
    }

    
    
    var startTime = TimeInterval()
    var timer = Timer()
    
    //starts the timer
    func startTimer(_ sender: AnyObject) {
        if !timer.isValid {
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: sender, selector: #selector(ViewController.updateTime), userInfo: nil, repeats:true)
            startTime = Date.timeIntervalSinceReferenceDate
        }
    }
    // calculates the elapsed time in seconds (Double = NSTimeInterval).extension NStimeInterval
    func updateTime() {
        //find the difference between the current time and the start time and return a string out of it
        // updates the text field
        LabelTimer.text = (Date.timeIntervalSinceReferenceDate - startTime).time
    }
    
    
    
    
}

extension TimeInterval {
    var time:String {
        //return String(format:"%02d:%02d:%02d.%02d", Int(self/360.0), Int((self/60.0) % 60), Int((self) % 60 ), Int(self*100 % 100 ))
        return String(format:"%02d:%02d:%02d", Int(self/360.0), Int((self/60.0).truncatingRemainder(dividingBy: 60)), Int((self).truncatingRemainder(dividingBy: 60) ))
    }
}

