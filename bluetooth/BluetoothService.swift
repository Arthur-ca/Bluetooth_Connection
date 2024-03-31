//
//  BluetoothService.swift
//  bluetooth
//
//  Created by Jiahao Chen on 2024-03-31.
//

import Foundation
import CoreBluetooth

enum ConnectionStatus: String{
    case connected
    case disconnected
    case scanning
    case connecting
    case error
}

/*
struct characteristic{
    let uuid: CBUUID
    let name: String
}*/

let sensorService: CBUUID = CBUUID(string: "")
let sensorCharacteristic: CBUUID = CBUUID(string: "")

class BluetoothService: NSObject, ObservableObject{
    
    private var centralManager: CBCentralManager!
    
    var sensorPeripheral: CBPeripheral?
    @Published var peripheralStatus: ConnectionStatus = .disconnected
    @Published var humidityValue: Float = 0.0
    
    override init(){
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func scanForPeripherals(){
        peripheralStatus = .scanning
        centralManager.scanForPeripherals(withServices: [sensorService])
    }
}


extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth Power On")
            scanForPeripherals()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Need to fill in your device name
        if peripheral.name == "" {
            print("Discovered \(peripheral.name ?? "no name")")
            sensorPeripheral = peripheral
            centralManager.connect(peripheral)
            peripheralStatus = .connecting
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheralStatus = .connected
        
        peripheral.delegate = self
        peripheral.discoverServices([sensorService])
        centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        peripheralStatus = .disconnected
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        peripheralStatus = .error
        print(error?.localizedDescription ?? "no error")
    }
}


extension BluetoothService: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? []{
            if service.uuid == sensorPeripheral {
                print("found service for \(sensorService)")
                peripheral.discoverCharacteristics([sensorCharacteristic], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] {
            peripheral.setNotifyValue(true, for: characteristic)
            print("found characteristic, waiting on values.")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == sensorCharacteristic {
            guard let data = characteristic.value else{
                print("No data received for \(characteristic.uuid.uuidString)")
                return
            }
            
            let sensorData: Float = data.withUnsafeBytes { $0.pointee }
            humidityValue = sensorData
        }
    }
}
