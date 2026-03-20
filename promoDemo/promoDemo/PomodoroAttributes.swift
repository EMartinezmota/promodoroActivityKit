//
//  PomodoroAttributes.swift
//  promoDemo
//
//  Created by Esteban  Martinez Mota on 3/19/26.
//
//Step 6
import ActivityKit

struct PomodoroAttributes: ActivityAttributes {

    // Fixed data for the entire activity
    public struct ContentState: Codable, Hashable {

        // Dynamic values that change during the activity
        var phase: String
        var round: Int
        var remainingTime: Int
    }

    // Fixed values that never change after the activity starts
    var totalRounds: Int
}
