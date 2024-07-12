//
//  AuthorizationStatus.swift
//  GizoSDK
//
//  Created by Meysam Farmani on 7/12/24.
//

enum AuthorizationStatus : Int{
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
    case authorizedAlways = 4
}
