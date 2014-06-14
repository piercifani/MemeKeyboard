//
//  PCCoreDataStack+Meme.swift
//  MemeKeyboard
//
//  Created by Pierluigi Cifani on 14/6/14.
//  Copyright (c) 2014 Voalte. All rights reserved.
//

import Foundation

let MemeEntityName :String      = "Meme"
let MemeEntityFRCCache :String  = "MemeEntityFRCCache"

typealias MemeCreationHandler = (meme: Meme?, error: NSError?) -> ()

extension PCCoreDataStack {

    func memeEntityDescription (moc :NSManagedObjectContext?) -> NSEntityDescription{
        
        var context = moc
        
        if context == nil {
            context = defaultContext()
        }
        
        let entityDescription = NSEntityDescription.entityForName(MemeEntityName, inManagedObjectContext: context)
        return entityDescription
    }
    
    func memesFRC () -> NSFetchedResultsController! {
        
        let mainContext = defaultContext()
        let entityDescription = memeEntityDescription(nil)
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entityDescription
        fetchRequest.fetchBatchSize = 20
        
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let memesFRC = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: mainContext, sectionNameKeyPath: nil, cacheName: MemeEntityFRCCache)
        
        return memesFRC;
    }
    
    func createMeme (name :String, url :String, tags :String[], completionBlock: MemeCreationHandler) {
        
        let operationBlock: (NSManagedObjectContext) -> Void = {moc in

            let createdMeme = Meme(entity: self.memeEntityDescription(moc), insertIntoManagedObjectContext: moc)
            
        }

        let completionBlock: (NSError) -> Void = {error in
            //Handle error
        }

        performBackgroundCoreDataOperation(operationBlock as PCBackgroundCoreDataBlock, completionBlock as PCBackgroundCoreDataCompletionBlock)
    }
}
