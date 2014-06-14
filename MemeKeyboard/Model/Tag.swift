//
//  Tag.swift
//  MemeKeyboard
//
//  Created by Pierluigi Cifani on 13/6/14.
//  Copyright (c) 2014 Voalte. All rights reserved.
//

import CoreData

class Tag: NSManagedObject {
   
    @NSManaged var name : NSString
    @NSManaged var memes : NSSet

}
