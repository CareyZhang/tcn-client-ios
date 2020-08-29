//
//  File.swift
//  
//
//  Created by Carey Zhang on 2020/7/24.
//

import Foundation
import SQLite3

public class DBManager: NSObject{
    public var db: OpaquePointer?
    private let dbURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("tcn.sqlite")
    
    public override init() {
        if sqlite3_open(dbURL.path, &db) == SQLITE_OK {
            print("Successfully opened connection to database at \(dbURL.path)")
            
            var createRXTableSQL = "create table if not exists rx_tcn(closestEstimatedDistance DOUBLE, rssi DOUBLE, rxMUUIDShort TEXT, rxtcn TEXT, tcn TEXT, txMUUID TEXT, txMUUIDShort TEXT, latitude DOUBLE, longitude DOUBLE, power DOUBLE, unixTimestamp INTEGER);"
            if sqlite3_exec(db, createRXTableSQL, nil, nil, nil) != SQLITE_OK{
                print("create table fail.")
                return
            }
            
            var createTXTableSQL = "create table if not exists tx_tcn(batteryLevel DOUBLE, gpsStatus INTEGER, motionStatus INTEGER, ownTCN TEXT, txMUUID TEXT, txMUUIDShort TEXT, txtcn TEXT, latitude DOUBLE, longitude DOUBLE, unixTimestamp INTEGER);"
            
            if sqlite3_exec(db, createTXTableSQL, nil, nil, nil) != SQLITE_OK{
                print("create RX table fail.")
                return
            }
            
            print("create table ok.")
        } else {
            print("Unable to open database.")
            return
        }
    }
    
    public func insertRXTCN(closestEstimatedDistance: Double, rssi: Float, rxMUUIDShort: String, rxtcn: String, tcn: String, txMUUID: String, txMUUIDShort: String, latitude: Double, longitude: Double, txPower: Double, unixTimestamp: Int){
        var insertsql = "INSERT INTO rx_tcn (closestEstimatedDistance, rssi, rxMUUIDShort, rxtcn, tcn, txMUUID, txMUUIDShort, latitude, longitude, power, unixTimestamp) VALUES (?,?,?,?,?,?,?,?,?,?,?);"
        var insertStatement:OpaquePointer? = nil
        //NSLog("insert Database Error Message : %s", sqlite3_errmsg(db));
        if sqlite3_prepare_v2(db, insertsql, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_double(insertStatement, 1, Double(closestEstimatedDistance))
            sqlite3_bind_double(insertStatement, 2, Double(rssi))
            sqlite3_bind_text(insertStatement, 3, (rxMUUIDShort as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, (rxtcn as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 5, (tcn as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, (txMUUID as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (txMUUIDShort as NSString).utf8String, -1, nil)
            sqlite3_bind_double(insertStatement, 8, Double(UserDefaults.standard.value(forKey: "Latitude") as! Double))
            sqlite3_bind_double(insertStatement, 9, Double(UserDefaults.standard.value(forKey: "Longitude") as! Double))
            sqlite3_bind_double(insertStatement, 10, Double(txPower) as! Double)
            sqlite3_bind_int(insertStatement, 11, Int32(unixTimestamp))
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully insert row.")
                print("insert rx tcn with location : \(txPower) \(UserDefaults.standard.value(forKey: "Latitude")) \(UserDefaults.standard.value(forKey: "Longitude"))")
            } else {
                print("Could not insert row.")
            }
        }
        sqlite3_finalize(insertStatement)
    }
    
    public func insertTXTCN(batteryLevel: Double, gpsStatus:Bool, motionStatus:Bool, ownTCN:String, txMUUID:String, txMUUIDShort:String, txtcn:String, unixTimestamp:Int){
        var insertsql = "INSERT INTO tx_tcn (batteryLevel, gpsStatus, motionStatus, ownTCN, txMUUID, txMUUIDShort, txtcn, unixTimestamp) VALUES (?,?,?,?,?,?,?,?);"
        var insertStatement:OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertsql, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_double(insertStatement, 1, Double(batteryLevel))
            if gpsStatus{
                sqlite3_bind_int(insertStatement, 2, Int32(1))
            }
            else{
                sqlite3_bind_int(insertStatement, 2, Int32(0))
            }
            if motionStatus{
                sqlite3_bind_int(insertStatement, 3, Int32(1))
            }
            else{
                sqlite3_bind_int(insertStatement, 3, Int32(0))
            }
            sqlite3_bind_text(insertStatement, 4, (ownTCN as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 5, (txMUUID as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, (txMUUIDShort as NSString).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, (txtcn as NSString).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 8, Int32(unixTimestamp))
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully tx insert row.")
            } else {
                print("Could not insert row.")
            }
        }
        else{
            print("format error")
        }
        sqlite3_finalize(insertStatement)
    }
    
    public func delRXTCNs(sql:String){
        sqlite3_exec(db, sql, nil, nil, nil)
    }
    
    public func delTXTCNs(sql:String){
        sqlite3_exec(db, sql, nil, nil, nil)
    }
    
    public func selectRXTCNs(sql:String) -> [[String:Any]]{
        var queryStatement: OpaquePointer? = nil
        var RXTCNS: [[String:Any]] = []
        
        print("rx tcn sql: \(sql) ")
        NSLog("select Database Error Message : %s", sqlite3_errmsg(db));
        do{
            if sqlite3_prepare_v2(db, sql, -1, &queryStatement, nil) == SQLITE_OK{
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let closestEstimatedDistance = sqlite3_column_double(queryStatement, 0)
                    let rssi = Float(sqlite3_column_double(queryStatement, 1))
                    let rxMUUIDShort = String(describing: String(cString: sqlite3_column_text(queryStatement, 2)))
                    let rxtcn = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                    let tcn = String(describing: String(cString:sqlite3_column_text(queryStatement, 4)))
                    let txMUUID = String(describing: String(cString: sqlite3_column_text(queryStatement, 5)))
                    let txMUUIDShort = String(describing: String(cString: sqlite3_column_text(queryStatement, 6)))
                    let latitude = sqlite3_column_double(queryStatement, 7)
                    let longitude = sqlite3_column_double(queryStatement, 8)
                    let power = sqlite3_column_double(queryStatement, 9)
                    let unixTimestamp = Int(sqlite3_column_int(queryStatement, 10))
                    //var row = RX_TCN(closestEstimatedDistance: closestEstimatedDistance, rssi: rssi, rxMUUIDShort: rxMUUIDShort, rxtcn: rxtcn, tcn: tcn, txMUUID: txMUUID, txMUUIDShort: txMUUIDShort, unixTimestamp: unixTimestamp)
                    print("sql get rx tcn: \(closestEstimatedDistance) \(rssi) \(rxMUUIDShort) \(rxtcn) \(tcn) \(txMUUID) \(txMUUIDShort)  \(latitude) \(longitude) \(power) \(unixTimestamp)")
                    RXTCNS.append(["ID":0,"RX_MUUID_SHORT": rxMUUIDShort,"TX_MUUID":txMUUID,"TX_MUUID_SHORT":txMUUIDShort,"RX_TCN":rxtcn,"TCN":tcn, "RSSI": rssi,"DISTANCE":Float(closestEstimatedDistance),"LATITUDE":latitude,"LONGITUDE":longitude,"YOUR_IOS_SEND_TX_POWER":power,"UNIX_TIMESTAMP":Int(unixTimestamp)])
                }
            }
        }
        catch{
            print("select rx db error: \(error)")
        }
        sqlite3_finalize(queryStatement)
        return RXTCNS
    }
    
    public func selectTXTCNs(sql:String) -> [[String:Any]]{
        var queryStatement: OpaquePointer? = nil
        var TXTCNS: [[String:Any]] = []
        print("select txtcn prepare")
        do{
            if sqlite3_prepare_v2(db, sql, -1, &queryStatement, nil) == SQLITE_OK{
                print("select txtcn ok")
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    var batteryLevel = sqlite3_column_double(queryStatement, 0)
                    var gpsStatus = true
                    if Int32(sqlite3_column_int(queryStatement, 1)) == 0{
                        gpsStatus = false
                    }
                    var motionStatus = true
                    if Int32(sqlite3_column_int(queryStatement, 2)) == 0{
                        motionStatus = false
                    }
                    var ownTCN = String(describing: String(cString: sqlite3_column_text(queryStatement, 3)))
                    var txMUUID = String(describing: String(cString: sqlite3_column_text(queryStatement, 4)))
                    var txMUUIDShort = String(describing: String(cString: sqlite3_column_text(queryStatement, 5)))
                    var txtcn = String(describing: String(cString: sqlite3_column_text(queryStatement, 6)))
                    var unixTimestamp = Int(sqlite3_column_int(queryStatement, 7))
                    //var row = TX_TCN(batteryLevel: batteryLevel, gpsStatus: gpsStatus, motionStatus: motionStatus, ownTCN: ownTCN, txMUUID: txMUUID, txMUUIDShort: txMUUIDShort, txtcn: txtcn, unixTimestamp: unixTimestamp)
                    print("sql get tx tcn: \(batteryLevel) \(gpsStatus) \(motionStatus) \(ownTCN) \(txMUUID) \(txMUUIDShort) \(txtcn) \(unixTimestamp)")
                    
                    TXTCNS.append(["ID":0,"TX_MUUID": txMUUID, "TX_MUUID_SHORT": txMUUIDShort, "TX_TCN": txtcn, "OWN_TCN": ownTCN, "BATTERY_LEVEL": batteryLevel, "MOTION_STATUS": motionStatus, "GPS_STATUS": gpsStatus, "ANDROID_TX_POWER_LEVEL": -1, "UNIX_TIMESTAMP": unixTimestamp])
                }
            }
        }
        catch{
            print("select tx db error: \(error)")
        }
        sqlite3_finalize(queryStatement)
        
        return TXTCNS
    }
}


public class RX_TCN{
    var closestEstimatedDistance: Double
    var rssi: Float
    var rxMUUIDShort: String
    var rxtcn: String
    var tcn: String
    var txMUUID: String
    var txMUUIDShort: String
    var unixTimestamp: Int64
    
    init(closestEstimatedDistance: Double, rssi: Float, rxMUUIDShort: String, rxtcn: String, tcn: String, txMUUID: String, txMUUIDShort: String, unixTimestamp: Int) {
        self.closestEstimatedDistance = closestEstimatedDistance
        self.rssi = rssi
        self.rxMUUIDShort = rxMUUIDShort
        self.rxtcn = rxtcn
        self.tcn = tcn
        self.txMUUID = txMUUID
        self.txMUUIDShort = txMUUIDShort
        self.unixTimestamp = Int64(unixTimestamp)
    }
}

public class TX_TCN{
    var batteryLevel: Float
    var gpsStatus: Bool = false
    var motionStatus: Bool
    var ownTCN: String
    var txMUUID: String
    var txMUUIDShort: String
    var txtcn: String
    var unixTimestamp: Int64
    
    init(batteryLevel: Double, gpsStatus:Bool, motionStatus:Bool, ownTCN:String, txMUUID:String, txMUUIDShort:String, txtcn:String, unixTimestamp:Int) {
        self.batteryLevel = Float(batteryLevel)
        self.gpsStatus = gpsStatus
        self.motionStatus = motionStatus
        self.ownTCN = ownTCN
        self.txMUUID = txMUUID
        self.txMUUIDShort = txMUUIDShort
        self.txtcn = txtcn
        self.unixTimestamp = Int64(unixTimestamp)
    }
}
