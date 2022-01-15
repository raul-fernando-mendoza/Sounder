//
//  Log.swift
//  Sounder
//
//  Created by administrador on 14/01/22.
//

import Foundation

class Log{
    
    
    enum LogType: Int {
        case debug = 0, info = 1, error = 2
    }
    private static var level:LogType = LogType.debug;
    
    public static func debug(_ str:String){
      
        if( level.rawValue <= LogType.debug.rawValue ){
            print(str)
        }
    }
    public static func setLevel(_ newLevel:LogType){
        level = newLevel
    }
}
