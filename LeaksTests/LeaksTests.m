//
//  LeaksTests.m
//  Leaks
//
//  Created by Sash Zats on 2/12/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "RootViewController.h"
#import "LeaksInstrument.h"


@interface LeaksTests : XCTestCase
@property (nonatomic) LeaksInstrument *leaksInstrument;
@end


@implementation LeaksTests

- (void)setUp {
    [super setUp];
    
    self.leaksInstrument = [[LeaksInstrument alloc] init];
}

- (void)tearDown {
    // to make sure we are not holding leaked instances from the previous test.
    // Not that it matter if you use -[LeaksInstrument representativeSessions]
    self.leaksInstrument = nil;
 
    [super tearDown];
}

- (void)testFailingLeakingExample {
    XCTestExpectation *leaksExpectation = [self expectationWithDescription:@"No leaks detected"];
    
    [self _pushPopViewControllerNTimes:4 leak:YES progressHandler:^{
        [self.leaksInstrument measure];
    } completionHandler:^{
        XCTAssertFalse(self.leaksInstrument.hasLeaksInRepresentativeSession, @"%@", self.leaksInstrument);
        [leaksExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testPassingNotLeakingExample {
    XCTestExpectation *leaksExpectation = [self expectationWithDescription:@"No leaks detected"];
    
    [self _pushPopViewControllerNTimes:4 leak:NO progressHandler:^{
        [self.leaksInstrument measure];
    } completionHandler:^{
        XCTAssertFalse(self.leaksInstrument.hasLeaksInRepresentativeSession, @"%@", [self.leaksInstrument.representativeSessions componentsJoinedByString:@"\n"]);
        [leaksExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)_pushPopViewControllerNTimes:(NSUInteger)nTimes leak:(BOOL)leak progressHandler:(void(^)(void))progress completionHandler:(void(^)(void))handler {
    if (!nTimes) {
        handler();
        return;
    }

    [self _pushPopViewControllerLeak:leak withCompletionHandler:^{
        if (nTimes > 0) {
            progress();
        }
        [self _pushPopViewControllerNTimes:nTimes - 1 leak:leak progressHandler:progress completionHandler:handler];
    }];
}

- (void)_pushPopViewControllerLeak:(BOOL)leak withCompletionHandler:(void(^)(void))handler {
    UINavigationController *navigationController = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    RootViewController *rootViewController = navigationController.viewControllers.firstObject;
    if (leak) {
        [rootViewController pushLeakingViewController];
    } else {
        [rootViewController pushNotLeakingViewController];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [rootViewController.navigationController popToViewController:rootViewController
                                                            animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            handler();
        });
    });
}

@end
