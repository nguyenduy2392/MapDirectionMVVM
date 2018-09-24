//
//  DirectionViewModel.swift
//  MapDirectionMVVM
//
//  Created by duy on 9/19/18.
//  Copyright © 2018 app1 name. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Alamofire
import MapKit
//import ObservableArray_RxSwift

class DirectionViewModel {
  var routes: BehaviorRelay<[DirectionModel]> = BehaviorRelay(value: [])
  var origin: BehaviorRelay<String> = BehaviorRelay(value: "")
  var destination: BehaviorRelay<String> = BehaviorRelay(value: "")
  var annotationPosition: BehaviorRelay<Int> = BehaviorRelay(value: 0)
  var startPoint: Artwork? {
    get {
      guard let leg = getLeg() else {
        return nil
      }
      return Artwork(
        title: "Start",
        locationName: "",
        discipline: "",
        coordinate: CLLocationCoordinate2D(latitude: (leg.startLocation?.lat)!, longitude: (leg.startLocation?.lng)!),
        type: .start,
        rotate: 0,
        runTime: 0
      )
    }
  }
  var endPoint: Artwork? {
    get {
      guard let leg = getLeg() else {
        return nil
      }
      return Artwork(
        title: "End",
        locationName: "",
        discipline: "",
        coordinate: CLLocationCoordinate2D(latitude: (leg.endLocation?.lat)!, longitude: (leg.endLocation?.lng)!),
        type: .stop,
        rotate: 0,
        runTime: 0
      )
    }
  }
  var runPathPolyline: [Artwork] {
    get {
      guard let leg = getLeg() else {
        return []
      }
      var newRunPolyline: [Artwork] = []
      var index = 0
      for step in leg.steps! {
        var rotate: CLLocationDirection
        if index + 1 > leg.steps!.count - 1 {
          rotate = 0
        } else {
          let nextStep = leg.steps![index + 1]
        
          rotate = directionBetweenPoints(sourcePoint: CLLocationCoordinate2DMake(CLLocationDegrees((step.startLocation?.lat)!), CLLocationDegrees((step.startLocation?.lng)!)), CLLocationCoordinate2DMake(CLLocationDegrees((nextStep.startLocation?.lat)!), CLLocationDegrees((nextStep.startLocation?.lng)!)))
        }
        newRunPolyline.append(
          Artwork(
            title: "my car",
            locationName: "",
            discipline: "",
            coordinate: CLLocationCoordinate2DMake(CLLocationDegrees((step.startLocation?.lat)!), CLLocationDegrees((step.startLocation?.lng)!)),
            type: .car,
            rotate: rotate,
            runTime: Float((step.duration?.value)!)
          )
        )
        index += 1
      }
      return newRunPolyline
    }
  }
  var polyline: MKOverlay? {
    get {
      guard let leg = getLeg() else {
        return nil
      }
      let coords = leg.steps.map { steps in
        return steps.map { step in
          return CLLocationCoordinate2DMake(CLLocationDegrees((step.startLocation?.lat)!), CLLocationDegrees((step.startLocation?.lng)!))
        }
      }
      
      let myPolyline = MKPolyline(coordinates: coords!, count: (coords?.count)!)
      return myPolyline
    }
  }
  
  func loadRoutes() {
    let request = DirectionRequest(origin: origin.value, destination: destination.value)
    _ = APIClient.rx_request(request: request).subscribe(onNext: {[weak self] response in
      if response.status == "REQUEST_DENIED" {
        // Error
      }
      if response.status == "OK" {
        self?.routes.accept(response.response)
      }
    }, onError: nil, onCompleted: nil, onDisposed: nil)
  }
  
  func getLeg() -> Leg? {
    if self.routes.value.count == 0 {
      return nil
    }
    guard let leg = routes.value[0].legs?[0] else {
      return nil
    }
    return leg
  }
  
  func updatePosition() {

    if self.runPathPolyline.count > 0 {
      let step = 1
      guard self.annotationPosition.value + step < self.runPathPolyline.count
        else { return }

      self.annotationPosition.accept(self.annotationPosition.value + step)
      let nextMapPoint = self.runPathPolyline[self.annotationPosition.value]
      DispatchQueue.main.asyncAfter(deadline: .now() + Double(nextMapPoint.runTime / AppConstant.replaySpeed)) {
        self.updatePosition()
      }
    }
  }
  
  func resetPosition() {
    self.annotationPosition.accept(0)
  }
  
  private func directionBetweenPoints(sourcePoint: CLLocationCoordinate2D, _ destinationPoint: CLLocationCoordinate2D) -> CLLocationDirection {
    let pointX = destinationPoint.latitude - sourcePoint.latitude
    let pointY = destinationPoint.longitude - sourcePoint.longitude
    let degrees = radiansToDegrees(radians: atan2(pointY, pointX))
    let rotate = Int(degrees) % 360
    return CLLocationDirection(rotate)
  }
  
  private func radiansToDegrees(radians: Double) -> Double {
    return radians * 180 / Double.pi
  }
  
  private func degreesToRadians(degrees: Double) -> Double {
    return degrees * Double.pi / 180
  }
}
