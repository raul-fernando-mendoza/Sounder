//
//  queue.swift
//  Sounder
//
//  Created by administrador on 01/01/22.
//

import Foundation

let MAX_EVENT_TIME = 300

enum TypeEvent: CaseIterable {
    case rest, up, down, upDown, downUp
}

struct Gesture{
    var idx:Int
    var type:TypeEvent
    var agg:Float
    var delta:Float
    var level:Float
}

struct Queue {
    private var elements: [GiroEvent] = []
    
    private var limitsRestUp:[Float] = [0,0,0,0,0,0]
    private var limitsRestDown:[Float] = [0,0,0,0,0,0]
    private var limitsMoveUp:[Float] = [0,0,0,0,0,0]
    private var limitsMoveDown:[Float] = [0,0,0,0,0,0]
    
    private var movementsAgg:[Float] = [0.0, 0.0 ,0.0 ,0.0 ,0.0 ,0.0 ]
    private var movementsAggPrevious:[Float] = [0.0, 0.0 ,0.0 ,0.0 ,0.0 ,0.0 ]
    private var previousGesture:[Gesture?] = [Gesture?](repeating:nil, count: 6)
    
    private var initialized = false
    
    func span(_ value:Int,_ upperLimit:Int,_ lowerLimit:Int) -> Int{
        if( value > upperLimit){
            return value - upperLimit
        }
        else{
            return value - lowerLimit
        }
    }
    func toRange(_ value:Float,_ upperLimit:Float,_ lowerLimit:Float) -> Float{
        return (value) / (upperLimit - lowerLimit)
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
  mutating func push(_ e: GiroEvent) -> Gesture? {
      var g:Gesture? = nil
      elements.append(e)
      
      for i in 0...5{
          movementsAgg[i] = 0.0
      }
      
      let lastTime = e.getEndTime() - MAX_EVENT_TIME
      //first remove all old values
      while (self.head != nil) {
        let e:GiroEvent = self.head!
          if e.getStartTime() < lastTime{
              self.pop()
          }
          else{
              break
          }
      }
      // now sum all the rest and find the previous if exist
      for e in elements{
        if(e.getStartTime() >= lastTime){
            let translated = e.getTranslated()
            for i in 0...5{
                movementsAgg[i] += translated[i]
            }
        }
      }
      
      var str = "Agg:"
      
      for i in 0...5{
          str +=  String(format: "%.2f", movementsAgg[i]).leftPadding(toLength: 10, withPad: " ") + " "
      }
      Log.debug( str )
      
      if( initialized ){
          g =  recognizeDireccionChange(e)
      }
      movementsAggPrevious = movementsAgg
      
      return g

  }

  mutating func pop() -> GiroEvent? {
    guard !elements.isEmpty else {
      return nil
    }
    return elements.removeFirst()
  }

  var head: GiroEvent? {
    return elements.first
  }

  var tail: GiroEvent? {
    return elements.last
  }
  //agg degrees on the last half second
    mutating func getAggEvent() -> [Float]{
        return movementsAgg
    }

    /*
    mutating func recognizeRest(_ e:GiroEvent) -> Gesture?{
        var g:Gesture? = nil
        var isRest = true
        
        let idx = biggerIndexAgg(movementsAgg)
        
        
        for i in 0...2{
            if movementsAgg[i] < limitsRestDown[i] || limitsRestUp[i] < movementsAgg[i] {
                isRest = false
            }
        }
        if isRest == true {
            g = Gesture(idx:-1, type: TypeEvent.rest,agg: 0.0, delta: 0.0, level: 0.0)
            previousGesture[i] = g
        }
        else{
            g = nil
        }
        return g
    }
     */
    // return change of direccion
    mutating func recognizeDireccionChange(_ e:GiroEvent) -> Gesture?{
        var g:Gesture? = nil
        
        let idx = biggerIndexAgg(movementsAgg)
        
        //find out the delta
        let delta:Float =  movementsAgg[idx] - movementsAggPrevious[idx]
        
        //find out the level
        let pct:Float = toRange(movementsAgg[idx], limitsMoveUp[idx], limitsMoveDown[idx])
        
        
        if( ( previousGesture[idx] == nil || previousGesture[idx]!.type == TypeEvent.rest || previousGesture[idx]!.type == TypeEvent.down) &&  movementsAgg[idx] >= 5 ){
            g = Gesture(idx: idx, type: TypeEvent.up, agg: movementsAgg[idx], delta: delta,level: pct)
            previousGesture[idx] = g
            
        }
        else if ( ( previousGesture[idx] == nil || previousGesture[idx]!.type == TypeEvent.rest || previousGesture[idx]!.type == TypeEvent.up) &&  movementsAgg[idx] <= -5 ){
            g = Gesture(idx: idx, type: TypeEvent.down, agg: movementsAgg[idx], delta: delta,level: pct)
            previousGesture[idx] = g
            
        }
        else if abs(movementsAgg[idx]) < 5 {
            g = Gesture(idx:-1, type: TypeEvent.rest,agg: 0.0, delta: 0.0, level: 0.0)
            previousGesture[idx] = g
        }
        return g
        
    }


}
