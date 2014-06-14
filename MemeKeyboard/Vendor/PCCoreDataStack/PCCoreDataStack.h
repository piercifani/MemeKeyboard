//
//  PCCoreDataStack.h
//  PCCoreDataStack
//
//  Created by Pierluigi Cifani on 27/9/13.
//  Copyright (c) 2013 Pierluigi Cifani. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreData;

/**
 A block to be passed when doing background operations
 @param moc A \e NSManagedObjectContext where you will perform your operations
 */
typedef void(^PCBackgroundCoreDataBlock)(NSManagedObjectContext *moc);

/**
 A block to be passed when a background operation is finished
 @param error A \e NSError if an error saving to database occurred
 */
typedef void(^PCBackgroundCoreDataCompletionBlock)(NSError *error);


/**
 This class should be used as a wrapper for every \e CoreData operation you will perform in your application. To start using just do:
 @code
 NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
 [[PCCoreDataStack sharedInstance] setModelURL:modelURL];
 @endcode
 */

@interface PCCoreDataStack : NSObject

/**
 Returns the PCCoreData singleton.
 */

+ (instancetype) sharedInstance;

- (void) save;

/**
 Sets the \e NSURL where the model object is stored.
 */

- (void) setModelURL:(NSURL *)url;

- (void) clearDataBase;

/**
 Default \e NSManagedObjectContext.
 */
- (NSManagedObjectContext *) defaultContext;

/**
 Perform an \e CoreData operation in the background.
 @param operationBlock A block with the operation to perform in the background
 @param completionBlock A block to be executed on the main thread when the changes are merged into the default context
 
 */

- (void) performBackgroundCoreDataOperation:(PCBackgroundCoreDataBlock)operationBlock
                                 completion:(PCBackgroundCoreDataCompletionBlock)completionBlock;

/**
 Perform an \e CoreData operation in the background.
 @param operationBlock A block with the operation to perform in the background
 
*/

- (void) performBackgroundCoreDataOperation:(PCBackgroundCoreDataBlock)operationBlock;

@property(assign, nonatomic) NSInteger maxConcurrentOperations;

@end
