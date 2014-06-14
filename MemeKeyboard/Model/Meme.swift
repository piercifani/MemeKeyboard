//
//  Meme.swift
//  MemeKeyboard
//
//  Created by Pierluigi Cifani on 13/6/14.
//  Copyright (c) 2014 Voalte. All rights reserved.
//

import CoreData

class Meme: NSManagedObject {
    @NSManaged var title : NSString
    @NSManaged var url : NSString
    @NSManaged var tags : NSSet
}
