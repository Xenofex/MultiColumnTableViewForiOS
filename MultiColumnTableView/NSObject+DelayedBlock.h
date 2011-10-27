//
//  DelayedBlock.h
//  RenaultTraining
//
//  Created by Eli Wang on 11-8-23.
//  Copyright 2011年 ekohe.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (DelayedBlock)

- (void)performBlock:(void (^)(void))block afterDelay:(NSTimeInterval)delay;

@end
