//
//  Artwork.swift
//  MapDirectionMVVM
//
//  Created by duy on 9/19/18.
//  Copyright © 2018 app1 name. All rights reserved.
//

import Foundation
import MapKit
import Contacts

class Artwork: NSObject, MKAnnotation {
  let title: String?
  let locationName: String
  let discipline: String
  var coordinate: CLLocationCoordinate2D
  var type: AttractionType
  var rotate: CLLocationDirection
  var runTime: Float = 0
  
  init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D, type: AttractionType, rotate: CLLocationDirection, runTime: Float) {
    self.title = title
    self.locationName = locationName
    self.discipline = discipline
    self.coordinate = coordinate
    self.type = type
    self.rotate = rotate
    self.runTime = runTime
    
    super.init()
  }
  
  var subtitle: String? {
    return locationName
  }
  
  func mapItem() -> MKMapItem {
    let addressDict = [CNPostalAddressStreetKey: subtitle!]
    let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = title
    return mapItem
  }
}

enum AttractionType: Int {
  case start = 0
  case stop
  case car
  
  func image() -> UIImage {
    switch self {
    case .start:
      return resizeImage(image: #imageLiteral(resourceName: "start"), newWidth: 20.0)
    case .stop:
      return resizeImage(image: #imageLiteral(resourceName: "stop"), newWidth: 20.0)
    case .car:
      return resizeImage(image: #imageLiteral(resourceName: "car"), newWidth: 30.0)
    }
  }
}

func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
  
  let scale = newWidth / image.size.width
  let newHeight = image.size.height * scale
  UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
  image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
  let newImage = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  
  return newImage!
}
