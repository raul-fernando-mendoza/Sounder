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
    private var previousGesture:[Gesture?] = [Gesture?](repeating:nil,count:6)
    private var previousGestureChange:[Gesture?] = [Gesture?](repeating:nil,count:6)
    
   

    
    
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
      
      if let last = self.tail {
          let lastTime = last.getEndTime() - MAX_EVENT_TIME
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
      }
      
      
      
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


    mutating func recognizeRest(_ e:GiroEvent) -> Gesture?{
        var g:Gesture? = nil
        var isRest = true
        
        
        for i in 0...2{
            if movementsAgg[i] < limitsRestDown[i] || limitsRestUp[i] < movementsAgg[i] {
                isRest = false
            }
        }
        if isRest == true {
            g = Gesture(idx:-1, type: TypeEvent.rest,agg: 0.0, delta: 0.0, level: 0.0)
        }
        else{
            g = nil
        }
        return g
    }
    // return change of direccion
    mutating func recognizeDireccionChange(_ e:GiroEvent) -> Gesture?{
        var g:Gesture? = nil
        
        //first find de axis with the most change
        let agg = getAggEvent()
        let idx = biggerIndexAgg(movementsAgg)
        
        //find the actual direction
        var direction = TypeEvent.rest
        if movementsAgg[idx] > movementsAggPrevious[idx] {
            direction = TypeEvent.up
        }
        else{
            direction = TypeEvent.down
        }

        
        //find out the delta
        var delta:Float = 0.0
        if previousGesture[idx] != nil {
            delta = movementsAgg[idx] - movementsAggPrevious[idx]
        }
        
        //find out the level
        var pct:Float = 1.0
        
        
        
        // find out if there was a change of direction
        if let pg = previousGesture[idx] {
            if (idx == pg.idx){
                if pg.type == TypeEvent.up && direction==TypeEvent.down{
                    if let prevChange = previousGestureChange[idx] {
                        delta =  pg.agg - prevChange.agg
                        pct = toRange(abs(delta), limitsMoveUp[idx], limitsMoveDown[idx])
                    }
                    g = Gesture(idx: idx,type: TypeEvent.upDown,agg: pg.agg, delta: delta,level: pct)
                    previousGesture[idx] = g
                    previousGestureChange[idx] = g
                }
                else if pg.type == TypeEvent.down && direction==TypeEvent.up{
                    if let prevChange = previousGestureChange[idx] {
                        delta = pg.agg - prevChange.agg
                        pct = toRange(abs(delta), limitsMoveUp[idx], limitsMoveDown[idx])
                    }
                    g = Gesture(idx: idx, type: TypeEvent.downUp,agg: pg.agg, delta: delta,level: pct)
                    previousGesture[idx] = g
                    previousGestureChange[idx] = g
                }
                else{
                        g = Gesture(idx: idx, type: direction,agg: movementsAgg[idx], delta: delta,level: pct)
                        previousGesture[idx] = g
                }
            }
            else{
                    g = Gesture(idx: idx, type: direction,agg: movementsAgg[idx], delta: delta,level: pct)
                    previousGesture[idx] = g
            }
            
        }
        else{
            g = Gesture(idx: idx, type: direction,agg: movementsAgg[idx], delta: delta,level: pct)
            previousGesture[idx] = g
        }
       return g
        
    }


}
