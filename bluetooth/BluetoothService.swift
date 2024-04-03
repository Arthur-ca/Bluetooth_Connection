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

let sensorService: CBUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
let sensorCharacteristic: CBUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
let commandCharacteristic: CBUUID = CBUUID(string: "12345678-1234-1234-1234-123456789012")

@Observable
class BluetoothService: NSObject, ObservableObject{
    
    static let shared = BluetoothService()
    private var centralManager: CBCentralManager!
    
    var sensorPeripheral: CBPeripheral?
    var sendCharacteristic: CBCharacteristic?
    var peripheralStatus: ConnectionStatus = .disconnected
    var humidityValue: String = ""
    
    private override init(){
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}


extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth Power On")
            scanForPeripherals()
        }
    }
    
    func scanForPeripherals(){
        peripheralStatus = .scanning
        centralManager.scanForPeripherals(withServices: [sensorService])
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Need to fill in your device name
        if peripheral.name == "Morphace Mask" {
            print("Discovered \(peripheral.name ?? "no name")")
            sensorPeripheral = peripheral
            central.connect(peripheral)
            peripheralStatus = .connecting
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheralStatus = .connected
        peripheral.delegate = PeripheralManager.shared
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

@Observable
class PeripheralManager: NSObject, CBPeripheralDelegate {
    
    static let shared = PeripheralManager()
    private override init() {
        super.init()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services ?? []{
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == sensorCharacteristic{
                peripheral.setNotifyValue(true, for: characteristic)
                print("found characteristic, waiting on values.")
            } else if characteristic.uuid == commandCharacteristic {
                BluetoothService.shared.sendCharacteristic = characteristic
                print("found characteristic, ready to send command.")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else {
            print("No data received for \(characteristic.uuid.uuidString)")
            return
        }
        if characteristic.uuid == sensorCharacteristic {
            if let sensorData = String(data: data, encoding: .utf8) {
                BluetoothService.shared.humidityValue = sensorData
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == commandCharacteristic {
            if let error = error {
                print("Error writing command characteristic")
            } else {
                print("Command successfully written to characteristic.")
            }
        }
    }
}

