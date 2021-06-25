//
//  ThirdPartySDK.swift
//  Runner
//
//  Created by Amorn Apichattanakul on 24/6/21.
//

import Foundation

protocol ThirdPartySDKDelegate {
    func onFinish(value: String)
}

// Mocking 3rdParty SDK
class ThirdPartySDK {
    var delegate: ThirdPartySDKDelegate?
    var id: String?

    init(delegate: ThirdPartySDKDelegate, id: String) {
        self.delegate = delegate
        self.id = id
    }
    
    func start() {
        print("Start processing Mocking with Timer")
        let _ = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(self.thirdPartyDidFinished), userInfo: nil, repeats: false)
    }
    
    func process(id: String) -> String {
        let randomInt = Int.random(in: 0..<10)
        return "\(id) - \(randomInt)"
    }
    
    @objc func thirdPartyDidFinished() {
        let valueFromCallBack = "Hello from SDK! version \(id ?? "N/A") - SDK"
        delegate?.onFinish(value: valueFromCallBack)
    }
    
}
