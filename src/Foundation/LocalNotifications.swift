//
//  LocalNotifications.swift
//  NorthLib
//
//  Created by Ringo Müller on 22.11.21.
//  Copyright © 2021 Norbert Thies. All rights reserved.
//

import Foundation
import UserNotifications

open class LocalNotifications: DoesLog {
   
  //Helper to trigger local Notification if App is in Background
  public static func notifyUser(_ text:String = "Ausgabe wird derzeit im Hintergrund geladen"){
    
    let yourFireDate = Date().addingTimeInterval(5)
    
    let content = UNMutableNotificationContent()
    content.title = NSString.localizedUserNotificationString(forKey:
                                                              "Neue Ausgabe - \(text)", arguments: nil)
    content.body = NSString.localizedUserNotificationString(forKey: text, arguments: nil)
    content.categoryIdentifier = "Neue Ausgabe"
    content.sound = UNNotificationSound.default
    content.badge = 0
    
    let dateComponents = Calendar.current.dateComponents(Set(arrayLiteral: Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second), from: yourFireDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
    let request = UNNotificationRequest(identifier: "Ausgabe-\(yourFireDate.ddMMyy_HHmmss)a-\(text)", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
      if let error = error {
        Log.log("notification with error: \(error)")
      } else {
        Log.log("notification setup succeed")
      }
    })
    Log.log("notification added for \(yourFireDate.ddMMyy_HHmmss)")
  }
  
//  //Helper to trigger local Notification if App is in Background
//  public static func notify(title:String?,
//                            subTitle:String?,
//                            message:String,
//                            sound: UNNotificationSound = UNNotificationSound.default,
//                            launchImageName: String? = "NewIssueLaunch",
//                            badge: NSNumber?,
//                            attachment: URL?,
//                            delay: Int
//
//  ){
//    NewIssueLaunch
//    let yourFireDate = Date().addingTimeInterval(5)
//
//    let content = UNMutableNotificationContent()
//    content.title = NSString.localizedUserNotificationString(forKey:
//                                                              "Neue Ausgabe - \(text)", arguments: nil)
//    content.body = NSString.localizedUserNotificationString(forKey: text, arguments: nil)
//    content.categoryIdentifier = "Neue Ausgabe"
//    content.sound = UNNotificationSound.default
//    content.badge = 0
//
//    let dateComponents = Calendar.current.dateComponents(Set(arrayLiteral: Calendar.Component.year, Calendar.Component.month, Calendar.Component.day, Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second), from: yourFireDate)
//    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
//    let request = UNNotificationRequest(identifier: "Ausgabe-\(yourFireDate.ddMMyy_HHmmss)a-\(text)", content: content, trigger: trigger)
//    UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
//      if let error = error {
//        Log.log("notification with error: \(error)")
//      } else {
//        Log.log("notification setup succeed")
//      }
//    })
//    Log.log("notification added for \(yourFireDate.ddMMyy_HHmmss)")
//  }
}
