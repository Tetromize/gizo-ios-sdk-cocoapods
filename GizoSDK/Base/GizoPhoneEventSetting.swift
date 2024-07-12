//
//  GizoPhoneEventSetting.swift
//  GizoSDK
//
//  Created by Meysam Farmani on 7/12/24.
//

import UIKit

public class GizoPhoneEventSetting: GizoBaseSetting {
    public var allowPhoneEvent: Bool=false
    public var saveCsvFile: Bool=false
    public var fileLocation: String=FileLocationPath.Cache
}
