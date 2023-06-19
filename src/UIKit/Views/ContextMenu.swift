//
//  ContextMenu.swift
//
//  Created by Norbert Thies on 25.05.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/**
 A ContextMenu is used to display a context menu (if iOS >= 13) or an alert
 controller showing an action sheet when a long touch is performed on a
 certain view.
 */
open class ContextMenu: NSObject, UIContextMenuInteractionDelegate {
  
  /// The view on which to show the context menu
  public var view: UIView
  ///by default the UITargetedPreview animates from real size to ScreenFitting Size
  ///for a large image view in a scroll view, this can lead to an abnormal animation/behaviour
  public var smoothPreviewForImage: Bool = false
  /// prevent multiple appeariance of menu in iOS 12
  /// disabling the long Tap Gesture Recognizer did not worked
  private var open: Bool = false
  /// The argument to pass to menu item closures
  public var argument: Any? = nil
  
  /// Initialize with a view on which to define the context menu  
  public init(view: UIView, smoothPreviewForImage: Bool = false) {
    self.view = view
    self.smoothPreviewForImage = smoothPreviewForImage
    super.init()
  }
  
  /// Define the menu to display on long touch
  public var menu: [(title: String, icon: String, closure: (Any?)->())] = [] {
    willSet {
      if menu.count == 0 {
        view.isUserInteractionEnabled = true   
        view.addInteraction(UIContextMenuInteraction(delegate: self))
      }
    }
  }
  
  fileprivate func createFlatContextMenu() -> UIMenu {
    let menuItems = menu.map { m in
      UIAction(title: m.title,
               image: UIImage(name: m.icon) ?? UIImage(named: m.icon)) { [weak self] _ in
        m.closure(self?.argument)
      }
    }
    return UIMenu(title: "", children: menuItems)
  }

  
  fileprivate func createContextMenu() -> UIMenu {
    if groupedMenu.count > 0 {
      return createGroupedContextMenu()
    }
    return createFlatContextMenu()
  }
  
  /// Define the menu to display on long touch
  public var groupedMenu: [(title: String, icon: String, group: Int, closure: (Any?)->())] = [] {
    willSet {
      if menu.count == 0 {
        view.isUserInteractionEnabled = true
        view.addInteraction(UIContextMenuInteraction(delegate: self))
      }
    }
  }
  
  fileprivate func createGroupedContextMenu() -> UIMenu {
    var itms: [Int:[UIAction]] = [:]
    for m in groupedMenu {
      var subItems = itms[m.group] ?? []
      subItems.append(UIAction(title: m.title,
                         image: UIImage(name: m.icon)
                         ?? UIImage(named: m.icon)) { [weak self] _ in
        m.closure(self?.argument)
      })
      itms[m.group] = subItems
    }
    
    if itms.count == 1, let actions = itms.first?.value as? [UIAction] {
      return UIMenu(title: "", children: actions )
    }
    
    let menuItems
    = itms.sorted(by: { $0.key < $1.key })
      .map {_, itm in UIMenu(title: "",
                             options: .displayInline,
                             children:itm) }
    
    return UIMenu(title: "",
                  children:menuItems)
  }
  
  /// Add an additional menu item
  public func addMenuItem(title: String, icon: String, group: Int? = nil,
                          closure: @escaping (Any?)->()) {
    if let group = group {
      groupedMenu += (title: title, icon: icon, group: group, closure: closure)
    }
    else {
      menu += (title: title, icon: icon, closure: closure)
    }
  }
  
  // MARK: - UIContextMenuInteractionDelegate protocol

  @available(iOS 13.0, *)
  public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, 
    configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) 
    { _ -> UIMenu? in 
      return self.createContextMenu()
    }
  }
  
    
  @available(iOS 13.0, *)
  public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
    
    var imgV: UIImageView? = view as? UIImageView
    
    if imgV == nil {
      imgV = (view as? NorthUIKit.ImageView)?.imageView
    }
    
    guard self.smoothPreviewForImage == true,
          let imgV = imgV  else {
      //Use Default Menu Appeariance
      return nil
    }
    /// prevent the white background wich is default and appear in some cases as white outline
    let params = UIPreviewParameters()
    params.backgroundColor = .clear

    
    let preview = UIImageView(frame: CGRect(origin: CGPoint.zero,
                                            size: view.frame.size))
    preview.image = imgV.image
    preview.tintColor = .white
    preview.contentMode = imgV.contentMode
    return UITargetedPreview(view:preview,
                             parameters: params,
                             target: UIPreviewTarget(container: view.superview!,
                                                     center: view.center))
  }
} // ContextMenu
