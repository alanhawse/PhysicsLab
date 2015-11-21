//
//  Magnetometer.swift
//  Newton's Attic
//
//  Created by Alan Hawse on 7/16/15.
//  Copyright (c) 2015 Elkhorn Creek Engineering. All rights reserved.
//

import Foundation

class Magnetometer : ThreeAxisModeConvertor
{

    var heading : Double {
        get {
            //var heading : Double = 0.0
            if (val.y > 0.0)
            {
                return 90.0 - (atan(val.x / val.y) * (180.0 / 3.1415926));
            }
            else if (val.y < 0.0)
            {
                return 	-1.0 *  (atan(val.x / val.y) * (180 / 3.1415926));
            }
            else // hy = 0
            {
                if (val.x < 0.0) { return 180.0; }
                else { return 0.0; }
            }
        }
    }

}
