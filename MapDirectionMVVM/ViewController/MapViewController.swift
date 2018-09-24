//
//  MapViewController.swift
//  MapDirectionMVVM
//
//  Created by duy on 9/19/18.
//  Copyright © 2018 app1 name. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa

class MapViewController: UIViewController {

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var originTextField: UITextField!
  @IBOutlet weak var destinationTextField: UITextField!
  let initialLocation = CLLocation(latitude: 40.7428859, longitude: -74.00583979999999)
  let regionRadius: CLLocationDistance = 10000
  var directionViewModel = DirectionViewModel()
  var flightpathPolyline: MKPolyline!
  var runPathPolyline: [RunPolyline] = []
  var myLocation: Artwork!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self
    
    _ = originTextField.rx.text
      .map {$0 ?? ""}
      .bind(to: directionViewModel.origin)
    _ = destinationTextField.rx.text
      .map {$0 ?? ""}
      .bind(to: directionViewModel.destination)
    directionViewModel.isValid.subscribe(onNext: {[weak self] inValid in
      if inValid {
        self?.removeAll()
        self?.directionViewModel.resetPosition()
        self?.directionViewModel.loadRoutes()
      }
    })
    _ = directionViewModel.routes.asObservable().subscribe(onNext: {[weak self] _ in
      self?.mapView.removeAnnotations((self?.mapView.annotations)!)
      if (self?.directionViewModel.runPathPolyline.count)! > 0 {
        self?.myLocation = (self?.directionViewModel.runPathPolyline[(self?.directionViewModel.annotationPosition.value)!])!
        self?.mapView.addAnnotation((self?.directionViewModel.startPoint!)!)
        self?.mapView.addAnnotation((self?.directionViewModel.endPoint!)!)
        self?.mapView.addAnnotation((self?.myLocation)!)
        self?.mapView.add((self?.directionViewModel.polyline)!, level: .aboveRoads)
        self?.directionViewModel.updatePosition()
      }
    }, onError: nil, onCompleted: nil, onDisposed: nil)
 
    _ = directionViewModel.annotationPosition.asObservable().subscribe(onNext: {[weak self] annotationPosition in
      if (self?.directionViewModel.runPathPolyline.count)! > 0 {
        self?.mapView.removeAnnotations([(self?.myLocation)!])
        self?.myLocation = self?.directionViewModel.runPathPolyline[annotationPosition]
        self?.mapView.addAnnotation((self?.myLocation)!)
      }
    }, onError: nil, onCompleted: nil, onDisposed: nil)
    
    _ = directionViewModel.centerLocation.asObservable().subscribe(onNext: {[weak self] centerLocation in
      let coordinateRegion = MKCoordinateRegionMakeWithDistance(centerLocation.coordinate, AppConstant.regionRadius, AppConstant.regionRadius)
      self?.mapView.setRegion(coordinateRegion, animated: true)
    }, onError: nil, onCompleted: nil, onDisposed: nil)
  }
  
  func removeAll() {
    self.mapView.removeOverlays(self.mapView.overlays)
    self.mapView.removeAnnotations(self.mapView.annotations)
  }
}

extension MapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
    let annotationView = AttractionAnnotationView(annotation: annotation, reuseIdentifier: "Attraction")
    annotationView.canShowCallout = true
    
    return annotationView
  }

  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
               calloutAccessoryControlTapped control: UIControl) {
    let location = view.annotation as! Artwork
    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
    location.mapItem().openInMaps(launchOptions: launchOptions)
  }
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is MKPolyline {
      let lineView = MKPolylineRenderer(polyline: overlay as! MKPolyline)
      lineView.lineWidth = 3.0
      lineView.alpha = 0.5
      lineView.strokeColor = UIColor.blue
      mapView.renderer(for: overlay)
      return lineView
    }
    
    return MKOverlayRenderer()
  }
}

class AttractionAnnotationView: MKAnnotationView {
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    guard let attractionAnnotation = self.annotation as? Artwork else { return }
    
    image = attractionAnnotation.type.image()
    transform = CGAffineTransform(rotationAngle: CGFloat(attractionAnnotation.rotate * Double.pi / 180 ))
    layer.zPosition = attractionAnnotation.zPosition
  }
}
