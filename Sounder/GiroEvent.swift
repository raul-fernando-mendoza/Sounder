//
//  GiroEvent.swift
//  Sounder
//
//  Created by administrador on 02/01/22.
//

import Foundation

class GiroEvent {
    private var startTime:Int = 0
    private var endTime:Int = 0
    private var gXgYgZaXaYaZ:[Int] = [0,0,0,0,0,0]
    private var dXdYdZlXlYlZ:[Float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    private let g:Float = 16384
    
    init(startTime s:Int,endTime e:Int,raw:[Int]){
        startTime = s
        endTime = e
        gXgYgZaXaYaZ = raw
        for i in 0...2{
                let degrees = raw[i] / 250
                dXdYdZlXlYlZ[i] = (Float(endTime - startTime)/1000) * Float(degrees)
        }
        for i in 3...5{
                let accel:Float = Float(raw[i]) / g
                dXdYdZlXlYlZ[i] = pow((Float(endTime - startTime)/1000),2) * accel * 9.8
        }
    }
    public func getStartTime() -> Int{
        return startTime
    }
    public func getEndTime() -> Int{
        return endTime
    }

    public func getRaw() -> [Int]{
        return gXgYgZaXaYaZ
    }
    
    public func getTranslated() -> [Float]{
        return dXdYdZlXlYlZ
    }
}
