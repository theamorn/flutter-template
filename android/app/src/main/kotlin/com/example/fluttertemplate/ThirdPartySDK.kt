package com.example.fluttertemplate

import java.util.*
import kotlin.concurrent.schedule


interface ThirdPartySDKInterface {
    fun onFinish(value: String)
}

class ThirdPartySDK(var id: String) {

    init {

    }

    fun process(): String {
        val randomInt = (0..9).random()
        return "$id - $randomInt"
    }

    fun thirdPartyDidFinished(callback: (String) -> Unit) {
        val randomInt = (0..9).random()
        val valueFromCallBack = "SDK version $id Build: $randomInt - SDK"
        Timer().schedule(4000) {
            callback(valueFromCallBack)
        }
    }

}