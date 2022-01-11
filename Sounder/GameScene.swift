//
//  GameScene.swift
//  Sounder
//
//  Created by administrador on 27/12/21.
//

import SpriteKit
import GameplayKit
import CoreBluetooth
import AVFoundation

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let newLength = self.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
        }
    }
}



class GameScene: SKScene,  CBPeripheralDelegate, CBCentralManagerDelegate {
    
    private var label : SKLabelNode?
    private var statusLabel : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private var statusMsg:String = "Starting..."
    public var serviceUUID     = CBUUID.init(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
    public var characteristicUUID     = CBUUID.init(string: "0000FFE1-0000-1000-8000-00805F9B34FB")
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    private var message:String = ""
    var giroEventQueue = Queue()
    var timePreviousRead:Int = 0
    
    
    
    let xUpURL = Bundle.main.url(forResource: "python_sounds_dum", withExtension: "wav")
    var playerxUp:[AVAudioPlayer?] = []
    let xDownURL = Bundle.main.url(forResource: "python_sounds_tac", withExtension: "wav")
    var playerxDown:[AVAudioPlayer?] = []
    let yUpURL = Bundle.main.url(forResource: "python_sounds_4b", withExtension: "wav")
    let yDownURL = Bundle.main.url(forResource: "python_sounds_4c", withExtension: "wav")
    
     
    let xUp = SKAction.playSoundFileNamed("python_sounds_dum.wav", waitForCompletion: false)
    var xUpPlaying = false
    let xDown = SKAction.playSoundFileNamed("python_sounds_tac.wav", waitForCompletion: false)
    var xDownPlaying = false
    let yUp = SKAction.playSoundFileNamed("python_sounds_4b.wav", waitForCompletion: false)
    var yUpPlaying = false
    let yDown = SKAction.playSoundFileNamed("python_sounds_4c.wav", waitForCompletion: false)
    var yDownPlaying = false
    
    
    let gX = 0
    let gY = 1
    let gZ = 2
    let aX = 3
    let aY = 4
    let aZ = 5
  
 
    
    var limitsRestUp:[Float?] = [nil,nil,nil,nil,nil,nil]
    var limitsRestDown:[Float?] = [nil,nil,nil,nil,nil,nil]
    
    var limitsMoveUp:[Float?] = [nil,nil,nil,nil,nil,nil]
    var limitsMoveDown:[Float?] = [nil,nil,nil,nil,nil,nil]

    
    var buttonToggleStatus = true
    var buttonCurrentStatus = 1
    var buttonLastDownTime = 0
    var buttonLastUpTime = 0
    var setupRest = false
    var setupCnt = 0
    var setupMove = false
    var setupMoveCnt = 0
    
    let factor:Float = 0.4
    
    public func log(_ str:String){
        if( buttonToggleStatus ){
            print(str)
        }
    }
    
    public func setStatusMessage(msg:String){
        
        
        if let statusLabel = self.statusLabel {
            statusLabel.text = msg
        }
         
    }
    
    func play(_ soundFileURL:URL, volume:Float){
        do{
            
            /*if player != nil {
                if player!.isPlaying == false{
                    player = try AVAudioPlayer(contentsOf: soundFileURL)
                    print("playihg \(volume)")
                    player!.volume = volume
                    player!.play()
                }
            }
            else{*/
                let player = try AVAudioPlayer(contentsOf: soundFileURL)
                log("playihg \(volume)")
                player.volume = volume
                player.play()
            //}
           //}
        } catch{
            print("ERROR")
        }
    }
    
    override func sceneDidLoad(){
        
        do{
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSession.Category.playback,
                options: AVAudioSession.CategoryOptions.mixWithOthers
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            try playerxUp.append( AVAudioPlayer(contentsOf: xUpURL!) )
            try playerxUp.append( AVAudioPlayer(contentsOf: xUpURL!) )
            
            try playerxDown.append( AVAudioPlayer(contentsOf: xDownURL!) )
            try playerxDown.append( AVAudioPlayer(contentsOf: xDownURL!) )
        } catch{
            print("ERROR")
        }
        setStatusMessage(msg: "discovering BLE...")
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            setStatusMessage(msg: "Central is not powered on")
        } else {
            self.setStatusMessage(msg:"Central scanning for");
            centralManager.scanForPeripherals(withServices: [self.serviceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        // We've found it so stop scan
        self.setStatusMessage(msg:"peripheral found");
        self.centralManager.stopScan()

        // Copy the peripheral instance
        self.peripheral = peripheral
        self.peripheral.delegate = self

        // Connect!
        self.centralManager.connect(self.peripheral, options: nil)

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            self.setStatusMessage(msg:"Connecting to service")
            peripheral.discoverServices([serviceUUID])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == self.serviceUUID {
                    setStatusMessage(msg:"service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics([characteristicUUID], for: service)
                    return
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == characteristicUUID{
                    setStatusMessage(msg: "characteristic found")
                    peripheral.setNotifyValue( true, for: characteristic)
                }
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral,
           didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?){
        guard var data:Data = characteristic.value else { return }
        
        let received:String = String(data: data, encoding: .utf8)!
        //print(received)
        
        //print("byte by byte")
        while let b = data.popFirst() {
            //print("\(b) [\(Character(UnicodeScalar(b)))]")
            if b != 13 && b != 10 {
                message = message + String( Character(UnicodeScalar(b)) )
            }
            if b == 13 {
                //do nothing
                var x = b
            }
            else if b==10 {
                //print(message)
                var split = message.components(separatedBy: "\t")
                //var timeCurrent:Int? = nil
                if split.count == 8 {
                    do{
                        guard let timeCurrent:Int = Int(split[0]) else {
                            return
                        }
                        
                        let raw:[Int] = [ Int(split[1])!,
                                         Int(split[2])!,
                                         Int(split[3])!,
                                         Int(split[4])!,
                                         Int(split[5])!,
                                         Int(split[6])! ]
                        
                        let buttonStatus = Int(split[7])!
                        
                        processMessage(timeCurrent: timeCurrent,timePrevious: timePreviousRead,raw: raw,buttonStatus: buttonStatus)
                        timePreviousRead = timeCurrent
                        message = ""
                    }
                    catch{
                        print("An error has reading values from \(split)")
                    }
                }
            }
        }
    }
	
    func processMessage(timeCurrent:Int,timePrevious:Int,raw:[Int],buttonStatus:Int){
        let ge = GiroEvent( startTime: timePrevious,endTime: timeCurrent,raw: raw)

        if let gesture = giroEventQueue.push(ge){
            var str = "Agg:"
            let movementsAgg = giroEventQueue.getAggEvent()
            for i in 0...5{
                str +=  String(format: "%.2f", movementsAgg[i]).leftPadding(toLength: 10, withPad: " ") + " "
            }
            log( str )
            
            log("Gesture:\(gesture)")
            if gesture.type == TypeEvent.upDown  && gesture.agg > 3 && abs(gesture.delta) > 7 {
                log(">               >>>>>>>>>>>>>>>>>")
                
                if( playerxUp[0]!.isPlaying == false){
                    
                    playerxUp[0]!.volume = 1.0
                    playerxUp[0]!.play()
                }
                else if( playerxUp[1]!.isPlaying == false){
                    
                    playerxUp[1]!.volume = 1.0
                    playerxUp[1]!.play()
                }
                else{
                    print("ªªªª ERROR UP is already playing")
                }
            }
            else if gesture.type == TypeEvent.downUp && gesture.agg < -3 &&  abs(gesture.delta) > 7 {
                
                log("<<<<<<<<<<<<<<<<                <")
                
                if( playerxDown[0]!.isPlaying == false){
                    playerxDown[0]!.volume = 1.0
                    playerxDown[0]!.play()
                }
                else if( playerxDown[1]!.isPlaying == false){
                    playerxDown[1]!.volume = 1.0
                    playerxDown[1]!.play()
                }
                else{
                    print("ªªªª ERROR DOWN is already playing")
                }
            }
            
        }
        
       
        var str:String = String(format: "%d", timeCurrent).leftPadding(toLength: 6, withPad: " ") + " "
        
        for i in 0...5{
            str += String(format: "%d", raw[i]).leftPadding(toLength: 6, withPad: " ") + " "
        }
        let translated = ge.getTranslated()
        for i in 0...5{
            str += String(format: "%.2f", translated[i]).leftPadding(toLength: 6, withPad: " ") + " "
        }
        str += String(buttonStatus)
        log(str)
        
        if buttonCurrentStatus==1 && buttonStatus == 0 {
            buttonCurrentStatus = 0
            buttonLastDownTime = timeCurrent
        }
        if buttonCurrentStatus==0 && buttonStatus == 1{
            buttonCurrentStatus = 1
            buttonLastUpTime = timeCurrent
        
            if (buttonLastUpTime - buttonLastDownTime) >= 2000 && (buttonLastUpTime - buttonLastDownTime) < 4000{

            }
            if (buttonLastUpTime - buttonLastDownTime) < 1000 {
                buttonToggleStatus  = !buttonToggleStatus
            }
        }
        let aggregated = giroEventQueue.getAggEvent()
        if setupRest == true{
            for i in 0...5 {
                if limitsRestUp[i] == nil || aggregated[i] > limitsRestUp[i]! {
                    limitsRestUp[i] = aggregated[i]
                }
                if limitsRestDown[i] == nil || aggregated[i] < limitsRestDown[i]!{
                    limitsRestDown[i] = aggregated[i]
                }
            }
            setupCnt += 1;
            self.setStatusMessage(msg: "stand still \(setupCnt)")
            if setupCnt > 100 {
                self.setupRest = false
                setupCnt=0
                self.setStatusMessage(msg: "you can move")
                var strUp = ""
                var strDown = ""
                for i in 0...5 {
                    strUp +=  String(format: "%d", self.limitsRestUp[i]!).leftPadding(toLength: 10, withPad: " ") + " "
                    strDown += String(format: "%d", self.limitsRestDown[i]!).leftPadding(toLength: 10, withPad: " ") + " "
                }
                log("limits")
                log(strUp)
                log(strDown)
                
                giroEventQueue.setlimitsRestUp([limitsRestUp[0]!,
                                                limitsRestUp[1]!,
                                                limitsRestUp[2]!,
                                                limitsRestUp[3]!,
                                                limitsRestUp[4]!,
                                                limitsRestUp[5]!])
                giroEventQueue.setlimitsRestDown([limitsRestDown[0]!,
                                                  limitsRestDown[1]!,
                                                  limitsRestDown[2]!,
                                                  limitsRestDown[3]!,
                                                  limitsRestDown[4]!,
                                                  limitsRestDown[5]!])
                
                
            }
        }
        if setupMove == true{
            for i in [Int](0...5) {
                if limitsMoveUp[i] == nil || aggregated[i] > limitsMoveUp[i]! {
                    limitsMoveUp[i] = aggregated[i]
                }
                if limitsMoveDown[i] == nil || aggregated[i] < limitsMoveDown[i]!{
                    limitsMoveDown[i] = aggregated[i]
                }
            }
            setupMoveCnt += 1;
            self.setStatusMessage(msg: "keep moving \(setupMoveCnt)")
            if setupMoveCnt > 200 {
                self.setupMove = false
                setupMoveCnt = 0
                self.setStatusMessage(msg: "you can STOP moving")
                var strUp = ""
                var strDown = ""
                for i in [Int](0...5) {
                    strUp +=  String(format: "%d", self.limitsMoveUp[i]!).leftPadding(toLength: 10, withPad: " ") + " "
                    strDown += String(format: "%d", self.limitsMoveDown[i]!).leftPadding(toLength: 10, withPad: " ") + " "
                }
                log("limits Moving")
                log(strUp)
                log(strDown)
                giroEventQueue.setlimitsMoveUp([limitsMoveUp[0]!,
                                                limitsMoveUp[1]!,
                                                limitsMoveUp[2]!,
                                                limitsMoveUp[3]!,
                                                limitsMoveUp[4]!,
                                                limitsMoveUp[5]!])
                giroEventQueue.setlimitsMoveDown([limitsMoveDown[0]!,
                                                  limitsMoveDown[1]!,
                                                  limitsMoveDown[2]!,
                                                  limitsMoveDown[3]!,
                                                  limitsMoveDown[4]!,
                                                  limitsMoveDown[5]!])
                
            }
        }
        
        if buttonToggleStatus == false && setupRest == false && setupMove == false && limitsRestUp[gX] != nil && limitsMoveUp[gX] != nil {
            log("")
            
        }

    }
        
    override func didMove(to view: SKView) {
        
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        self.statusLabel = self.childNode(withName: "//statusLabel") as? SKLabelNode
        if let statusLabel = self.statusLabel {
            statusLabel.alpha = 0.0
            statusLabel.text = self.statusMsg
            statusLabel.run(SKAction.fadeIn(withDuration: 2.0))
        }

        

        
        
        /* Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
         */
    }
    

    
    func touchDown(atPoint pos : CGPoint) {
        print("touche down")
        

    }
    
    func touchMoved(toPoint pos : CGPoint) {
        let node = self.childNode(withName: "//statusLabel") as? SKLabelNode
        /*
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
         */
    }
    
    func touchUp(atPoint pos : CGPoint) {
        let node = self.childNode(withName: "//statusLabel") as? SKLabelNode
        /*
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
         */
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let buttonSetup = self.childNode(withName: "//buttonSetup") as? SKLabelNode
        let buttonMoveSetup = self.childNode(withName: "//buttonMoveSetup") as? SKLabelNode
        

        
        for t in touches {
            if buttonSetup!.contains(t.location(in: self)){
                self.setupRest = true
                self.setupCnt = 0
                self.setStatusMessage(msg: "Please do NOT move")
                for (i, _) in self.limitsRestUp.enumerated() {
                    self.limitsRestUp[i] = nil
                    self.limitsRestDown[i] = nil
                }
                break
            }
            if buttonMoveSetup!.contains(t.location(in: self)){
                self.setupMove = true
                self.setupMoveCnt = 0
                self.setStatusMessage(msg: "Please move A LOT")
                for (i, _) in self.limitsMoveUp.enumerated() {
                    self.limitsMoveUp[i] = nil
                    self.limitsMoveDown[i] = nil
                }
                break
            }
         
         }

        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let node = self.childNode(withName: "//statusLabel") as? SKLabelNode
        //for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
