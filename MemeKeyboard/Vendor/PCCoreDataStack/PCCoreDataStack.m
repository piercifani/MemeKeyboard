//
//  PCCoreDataStack.m
//  PCCoreDataStack
//
//  Created by Pierluigi Cifani on 27/9/13.
//  Copyright (c) 2013 Pierluigi Cifani. All rights reserved.
//

#import "PCCoreDataStack+Private.h"

@import UIKit;

NSString *DefaultMOCDidMerge = @"DefaultMOCDidMerge";

NSString *PCCoreDataStackWillClearDatabaseNotification = @"PCCoreDataStackWillClearDatabaseNotification";

@interface PCCoreDataStack ()

@end

@implementation PCCoreDataStack

+ (instancetype) sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(instancetype) init
{
    if(self = [super init]){
        self.maxConcurrentOperations = 2;
    }
    return self;
}


- (void) startCoreDataStack
{
    //Kick things off
    [self managedObjectContext];
    
    _backgroundOperationQueue = [[NSOperationQueue alloc] init];
    _backgroundOperationQueue.maxConcurrentOperationCount = self.maxConcurrentOperations;
    
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(save:)
                                   userInfo:nil
                                    repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(save:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
}

- (void) setModelURL:(NSURL *)url;
{
    if (url)
    {
        _modelURL = url;
        [self startCoreDataStack];
    }
}

- (void) clearDataBase;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:PCCoreDataStackWillClearDatabaseNotification
                                                        object:nil];
    
    [self.backgroundOperationQueue cancelAllOperations];
    
    [self.managedObjectContext lock];
    NSArray *stores = [self.persistentStoreCoordinator persistentStores];
    
    for(NSPersistentStore *store in stores) {
        [self.persistentStoreCoordinator removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    
    [self.managedObjectContext unlock];
    self.managedObjectModel    = nil;
    self.managedObjectContext  = nil;
    self.persistentStoreCoordinator = nil;
    
    //Kick things off again
    [self defaultContext];
}

- (void) save
{
    [self save:nil];
}

- (void) save:(id)value
{
    NSError *error;
    [self.managedObjectContext save:&error];
    if (error) {
        NSLog(@"Can't save, something's really wrong");
    }
}

- (NSManagedObjectContext *) defaultContext;
{
    return self.managedObjectContext;
}

- (NSManagedObjectContext *) backgroundContext;
{
    NSAssert(![NSThread isMainThread], @"call this from another thread");
    NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] init];
    backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    return backgroundContext;
}

- (void)mergeChanges:(NSNotification *)notification {
    
    if (notification.object != self.managedObjectContext) {
        [self performSelectorOnMainThread:@selector(updateMainContext:)
                               withObject:notification
                            waitUntilDone:NO];
    }
}

- (void)updateMainContext:(NSNotification *)notification
{
    assert([NSThread isMainThread]);
    
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DefaultMOCDidMerge
                                                        object:notification.object];
}

#pragma mark - API

- (void) performBackgroundCoreDataOperation:(PCBackgroundCoreDataBlock)operationBlock
                                 completion:(PCBackgroundCoreDataCompletionBlock)block;
{
    __block NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        // If cancelled, don't execute block
        if ([blockOperation isCancelled]) return;
        
        //Create Background MOC & execute user block
        NSManagedObjectContext *backgroundMOC = [self backgroundContext];
        operationBlock(backgroundMOC);
        
        // If cancelled, don't save block
        if ([blockOperation isCancelled]) return;
        
        /**
         *  Break retain cycle created by the __block attribute. This cost us more than a couple of hours.
         */
        blockOperation = nil;
        
        NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
        __weak NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        __block NSError *error;
        
        if ([backgroundMOC hasChanges])
        {
            //Schedule a listener for the mainQueue merge
            __block id observer = [center addObserverForName:DefaultMOCDidMerge
                                                      object:backgroundMOC
                                                       queue:mainQueue
                                                  usingBlock:^(NSNotification *note) {
                                                      [center removeObserver:observer];
                                                      
                                                      if (block) block(error);
                                                  }];
            //Save
            [backgroundMOC save:&error];
            
            if (error)
            {
                NSLog(@"Some error happened saving: %@", error); //Maybe we should handle this in a better way
            }
        }
        else
        {
            [mainQueue addOperationWithBlock:^{
                if (block) block(error);
            }];
        }
    }];
    
    [self.backgroundOperationQueue addOperation:blockOperation];
}

- (void) performBackgroundCoreDataOperation:(PCBackgroundCoreDataBlock)operationBlock;
{
    [self performBackgroundCoreDataOperation:operationBlock completion:nil];
}

#pragma mark - Core Data stack

// Returns the path to the application's documents directory.
- (NSString *)applicationDocumentsDirectory {
    
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
//
- (NSManagedObjectContext *)managedObjectContext {
	
    NSAssert(self.modelURL != nil, @"Set a URL model before doing this!");
    
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [NSManagedObjectContext new];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    // observe the ParseOperation's save operation with its managed object context
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mergeChanges:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
//
- (NSManagedObjectModel *)managedObjectModel {
	
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = self.modelURL;
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it
//
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *prodName = [info objectForKey:@"CFBundleDisplayName"];
    
    // find the earthquake data in our Documents folder
    NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", prodName]];
    NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption : @YES,
                              NSMigratePersistentStoresAutomaticallyOption: @YES
                              };
    
    NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
    }
    
    return _persistentStoreCoordinator;
}

@end
