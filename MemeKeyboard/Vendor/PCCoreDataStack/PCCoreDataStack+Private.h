//
//  PCCoreDataStack+Private.h
//  PCCoreDataStack
//
//  Created by Pierluigi Cifani on 21/11/13.
//  Copyright (c) 2013 Voalte Inc. All rights reserved.
//

#import "PCCoreDataStack.h"

extern NSString *PCCoreDataStackWillClearDatabaseNotification;

@interface PCCoreDataStack ()

@property (nonatomic, strong) NSURL *modelURL;

@property (nonatomic, strong) NSOperationQueue *backgroundOperationQueue;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@end
