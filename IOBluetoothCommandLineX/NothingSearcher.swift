//
//  NothingSearcher.swift
//  IOBluetoothCommandLineX
//
//  Created by Arunavo Ray on 24/01/23.
//

import Foundation

import Foundation
import IOBluetooth

protocol NothingDevice {
    func getDevice() -> IOBluetoothDevice;
    func getService() -> IOBluetoothSDPServiceRecord;
    func isConnected() -> Bool;
}

class NothingSearcher : NothingDevice {
    private var _device : IOBluetoothDevice? = nil
    private var _service : IOBluetoothSDPServiceRecord? = nil
    
    init() {
        scan()
    }
    
    func scan() {
        // Do not scan if we already scanned for the devices
        if _device != nil && _service != nil {
            return
        }
        
        let pairedDevices = IOBluetoothDevice.pairedDevices().filter{ $0 is IOBluetoothDevice }.map{ $0 as! IOBluetoothDevice }
        for dev in pairedDevices {
            scan(device: dev);
        }
    }
    
    func scan(device : IOBluetoothDevice) {
        // Do not scan if we already scanned for the devices
        if _device != nil && _service != nil {
            return
        }
        
        if (device.services != nil)
        {
            for service in device.services! {
                if (service as? IOBluetoothSDPServiceRecord)?.getServiceName() == "nothinginteraction" {
                    _device = device
                    _service = service as? IOBluetoothSDPServiceRecord
                    return
                }
            }
        }
    }
    
    func isConnected() -> Bool {
        if _device == nil {
            return false
        }
        else {
            return _device!.isConnected()
        }
    }

    func getDevice() -> IOBluetoothDevice {
        // Will cause runtime error if no device found
        return _device!
    }
    
    func getService() -> IOBluetoothSDPServiceRecord {
        // Will cause runtime error if no device found
        return _service!
    }
}
