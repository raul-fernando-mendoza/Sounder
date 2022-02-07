//
//  queue.swift
//  Sounder
//
//  Created by administrador on 01/01/22.
//

import Foundation

let MAX_EVENT_TIME = 300

enum EventType: CaseIterable {
    case rest, up, down, upDown, downUp, upSlowing, downSlowing, changeAxis
}

struct Gesture{
    var axis:Int = -1
    var directionCurrent:EventType = EventType.rest
    var directionPrevious:EventType = EventType.rest

    var valueCurrent:Float = 0.0
    var valuePrevious:Float = 0.0
    var max:Float = 0.0
    var min:Float = 0.0
    var deltaCurrent:Float = 0.0
    var deltaPrevious:Float = 0.0
    var level:Float = 0.0
    var added:Float = 0.0
    var addedPrevious:Float = 0.0
    
}

struct Queue {
    private var g:Gesture  = Gesture()
    
    private var limitsRestUp:[Float] = [0,0,0,0,0,0]
    private var limitsRestDown:[Float] = [0,0,0,0,0,0]
    private var limitsMoveUp:[Float] = [0,0,0,0,0,0]
    private var limitsMoveDown:[Float] = [0,0,0,0,0,0]
    
   
    private var initialized = false

    //find a value removing the rest values
    func removeRestValues(_ value:Int,_ upperLimit:Int,_ lowerLimit:Int) -> Int{
        if( value > upperLimit){
            return value - upperLimit
        }
        else{
            return value - lowerLimit
        }
    }
    func toRange(_ value:Float,_ upperLimit:Float,_ lowerLimit:Float) -> Float{
        return (value - lowerLimit) / (upperLimit - lowerLimit)
    }
    func biggerIndexAgg(_ values:[Float]) -> Int{
        var idx:Int = 0
        for i in 0...2{
            if  abs(values[i]) > abs(values[idx]){
                idx = i
            }
        }
        return idx
    }

    mutating func setlimitsRestDown(_ newValues:[Float] ){
        for i in 0...5{
          self.limitsRestDown[i] = newValues[i]
      }
    }
    mutating func setlimitsRestUp(_ newValues:[Float] ){
        for i in 0...5{
            self.limitsRestUp[i] = newValues[i]
      }
    }
    mutating func setlimitsMoveDown(_ newValues:[Float] ){
        for i in 0...5{
          self.limitsMoveDown[i] = newValues[i]
      }
    }
    mutating func setlimitsMoveUp(_ newValues:[Float] ){
        for i in 0...5{
            self.limitsMoveUp[i] = newValues[i]
        }
        if limitsMoveUp[0] > 0 {
            initialized = true
        }
    }
  mutating func add(_ e: GiroEvent) -> Gesture? {
    
      //first find out if the sensor is at rest
      let translated = e.getTranslated()
      var isRest:Bool = true
      for i in 0...2{
          if translated[i] < limitsRestDown[i] || limitsRestUp[i] < translated[i] {
              isRest = false
          }
      }

      if isRest == true {
          Log.debug("is at rest")
          g.directionCurrent = EventType.rest
          g.directionCurrent = EventType.changeAxis
          g.directionPrevious = EventType.changeAxis
          g.max = 0.0
          g.min = 0.0
          g.deltaCurrent = 0
          g.deltaPrevious = 0
          g.level = 0.0
          g.valueCurrent = 0.0
          g.valuePrevious = 0.0
          g.added = 0.0
          g.addedPrevious = 0.0
      }
      else{
        g.directionPrevious = g.directionCurrent
        g.deltaPrevious = g.deltaCurrent
        g.valuePrevious = g.valueCurrent
          
          //find out if the movement is still in the same axis as before if the axis have change reinitilize everything and start over
        let axis = biggerIndexAgg(e.getTranslated())
      
        if g.axis != axis{
            Log.debug("axis has changed")
            g.axis = axis
            g.directionCurrent = EventType.changeAxis
            g.directionPrevious = EventType.changeAxis
            g.max = 0.0
            g.min = 0.0
            g.deltaCurrent = 0
            g.deltaPrevious = 0
            g.level = 0.0
            g.valueCurrent = 0.0
            g.valuePrevious = 0.0
            g.added = 0.0
            g.addedPrevious = 0.0
        }
        else{
            //find out the direction of the change in value
            g.valueCurrent = translated[axis]
            g.added += g.valueCurrent
            if( g.valueCurrent >= g.valuePrevious){
                g.directionCurrent = EventType.up
            }
            else{
                g.directionCurrent = EventType.down
            }
            g.deltaCurrent = abs(abs(g.valueCurrent) - abs(g.valuePrevious))
            if (g.directionPrevious == EventType.down || g.directionPrevious == EventType.downSlowing ) && g.directionCurrent == EventType.up {
                g.directionCurrent = EventType.downUp
                g.min = g.valuePrevious
                g.addedPrevious = g.added
                g.added = 0
            }
            else if (g.directionPrevious == EventType.up || g.directionPrevious == EventType.upSlowing) && g.directionCurrent == EventType.down{
                g.directionCurrent = EventType.upDown
                g.max = g.valuePrevious
                g.addedPrevious = g.added
                g.added = 0
            }
            else if g.deltaCurrent < g.deltaPrevious && g.valueCurrent >= g.valuePrevious{
                g.directionCurrent = EventType.upSlowing
                g.max = g.valueCurrent
            }
            else if g.deltaCurrent < g.deltaPrevious && g.valueCurrent < g.valuePrevious{
                g.directionCurrent = EventType.downSlowing
                g.min = g.valueCurrent
            }
                

            Log.debug("gesture:\(g)")
            
            
          
        }
      }
      return g
      
  }


     
   


}
