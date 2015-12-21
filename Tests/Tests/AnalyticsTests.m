//
//  AnalyticsTests.m
//  Bazaarvoice SDK
//
//  Copyright 2015 Bazaarvoice Inc. All rights reserved.
//

#import <AdSupport/ASIdentifierManager.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <BVSDK/BVConversations.h>
#import <BVSDK/BVAdvertising.h>
#import <BVSDK/BVRecommendations.h>

@interface BVAnalyticsTests : XCTestCase<BVDelegate> {
    XCTestExpectation *impressionExpectation;
    XCTestExpectation *pageviewExpectation;
    int numberOfExpectedImpressionAnalyticsEvents;
    int numberOfExpectedPageviewAnalyticsEvents;
}
@end

#define TEST_CLIENT_ID @"apitestclient"
#define IS_STAGING YES

@implementation BVAnalyticsTests

- (void)setUp
{
    [super setUp];
    
    // Conversations SDK set up. This is the deprecated method of setting up the Conversations SDK.
//    [BVSettings instance].staging = IS_STAGING;
//    [BVSettings instance].clientId = TEST_CLIENT_ID;
//    [BVSettings instance].passKey = @"2cpdrhohmgmwfz8vqyo48f52g";
    
    [BVSDKManager sharedManager].staging = IS_STAGING;
    [BVSDKManager sharedManager].clientId = TEST_CLIENT_ID;
    
    // BVConverstaions SDK API Key
    [BVSDKManager sharedManager].apiKeyConversations = @"2cpdrhohmgmwfz8vqyo48f52g";
    
    // BVRecommendations & BVAdvertising SDK key.
    [BVSDKManager sharedManager].apiKeyShopperAdvertising = @"4qhps77enfpw3kghuu8wendy";
    
    NSLog(@"BVSDK Info: %@", [BVSDKManager sharedManager].description);
    
    // Global logging level
    [[BVSDKManager sharedManager] setLogLevel:BVLogLevelError];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(analyticsPageviewEventCompleted:)
                                                 name:@"BV_INTERNAL_PAGEVIEW_ANALYTICS_COMPLETED"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(analyticsImpressionEventCompleted:)
                                                 name:@"BV_INTERNAL_MAGPIE_EVENT_COMPLETED"
                                               object:nil];
    
    impressionExpectation = [self expectationWithDescription:@"Expecting impression analytics events"];
    pageviewExpectation = [self expectationWithDescription:@"Expecting pageview analytics events"];
    numberOfExpectedImpressionAnalyticsEvents = 0;
    numberOfExpectedPageviewAnalyticsEvents = 0;
}

-(void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"BV_INTERNAL_PAGEVIEW_ANALYTICS_COMPLETED"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"BV_INTERNAL_MAGPIE_EVENT_COMPLETED"
                                                  object:nil];
}

-(void)waitForAnalytics {
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
        if(error)
        {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

-(void)analyticsImpressionEventCompleted:(NSNotification *)notification {
    
    NSLog(@"analytics impression event fired in tests: %i", numberOfExpectedImpressionAnalyticsEvents);
    
    NSError *err = (NSError *)[notification object];
    if (err){
        XCTFail(@"ERROR: Analytic event failed %@", err);
    } else {
        NSLog(@"Analytic Impression HTTP success.");
    }
    
    numberOfExpectedImpressionAnalyticsEvents -= 1;
    [self checkComplete];

}

-(void)analyticsPageviewEventCompleted:(NSNotification *)notification {

    NSLog(@"analytics pageview event fired in tests: %i", numberOfExpectedPageviewAnalyticsEvents);
    
    NSError *err = (NSError *)[notification object];
    if (err){
        XCTFail(@"ERROR: Analytic event failed %@", err);
    } else {
        NSLog(@"Analytic Page View HTTP success.");
    }
    
    numberOfExpectedPageviewAnalyticsEvents -= 1;
    [self checkComplete];

}

-(void)checkComplete {
    if(numberOfExpectedImpressionAnalyticsEvents == 0){
        [impressionExpectation fulfill];
        numberOfExpectedImpressionAnalyticsEvents = -1;
    }
    if(numberOfExpectedPageviewAnalyticsEvents == 0){
        [pageviewExpectation fulfill];
        numberOfExpectedPageviewAnalyticsEvents = -1;
    }
}

-(void)testAnalyticsCompletesSmall {
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 1;
    [self fireReviewAnalyticsCompletesWithLimit:1];
}

-(void)testAnalyticsCompletesBatched {
    
    numberOfExpectedPageviewAnalyticsEvents = 1;
#if ANALYTICS_STRATEGY_GET == 1
    numberOfExpectedImpressionAnalyticsEvents = 3;
#else 
    numberOfExpectedImpressionAnalyticsEvents = 1;
#endif
    [self fireReviewAnalyticsCompletesWithLimit:60];
}

-(void)testBigAnalyticsEvent {
    
    // bomb the analytics event with a ton of events, to make sure it doesn't crash.
    // crash would occur when objects were taken out of the queue in different threads - NSMutableArray is not thread safe
    // moving all array modifications to the main thread fixed the problem - only network requests happen on different threads now

#if ANALYTICS_STRATEGY_GET == 1
    // Not sure how many events, so this is just a stress test, but in GET case we never bother to wait on any events
    numberOfExpectedPageviewAnalyticsEvents = 0;
    numberOfExpectedImpressionAnalyticsEvents = 0;
#else
    numberOfExpectedPageviewAnalyticsEvents = 1;
    numberOfExpectedImpressionAnalyticsEvents = 1;
#endif
    
    BVGet *showDisplayRequest = [[ BVGet alloc ] initWithType:BVGetTypeReviews];
    [showDisplayRequest setLimit:100];
    [showDisplayRequest setSearch: @"Great sound"];
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    BVGet *showDisplayRequest2 = [[ BVGet alloc ] initWithType:BVGetTypeReviews];
    [showDisplayRequest2 setLimit:100];
    [showDisplayRequest2 setSearch: @"Great sound"];
    [showDisplayRequest2 addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest2 sendRequestWithDelegate:self];
    
    BVGet *showDisplayRequest3 = [[ BVGet alloc ] initWithType:BVGetTypeReviews];
    [showDisplayRequest3 setLimit:100];
    [showDisplayRequest3 setSearch: @"Great sound"];
    [showDisplayRequest3 addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest3 sendRequestWithDelegate:self];
    
#if ANALYTICS_STRATEGY_GET == 1
    [impressionExpectation fulfill];
    [pageviewExpectation fulfill];
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) { }];
#else
      [self waitForAnalytics];
#endif
    
}

-(void)fireReviewAnalyticsCompletesWithLimit:(int)limit {
    
    BVGet *showDisplayRequest = [[ BVGet alloc ] initWithType:BVGetTypeReviews];
    [showDisplayRequest setLimit:limit];
    [showDisplayRequest setSearch: @"Great sound"];
    [showDisplayRequest addSortForAttribute:@"Id" ascending:YES];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    [self waitForAnalytics];
}

-(void)testAnalyticsQuestion {
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 1;
    
    
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeQuestions];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"6055"];
    [showDisplayRequest setLimit:1];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    [self waitForAnalytics];
}

-(void)testAnalyticsStories {
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 0;
    
    
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeStories];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"14181"];
    [showDisplayRequest setLimit:1];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    [self waitForAnalytics];
}


-(void)testAnalyticsProducts {
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 1;
    
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeProducts];
    [showDisplayRequest setFilterForAttribute:@"CategoryId" equality:BVEqualityEqualTo value:@"testcategory1011"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeReviews forAttribute:@"Id" equality:BVEqualityEqualTo value:@"83501"];
    [showDisplayRequest setLimit:1];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    [self waitForAnalytics];
}

-(void)testAnalyticsCategories {
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 0;
    
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeCategories];
    [showDisplayRequest setFilterForAttribute:@"Id" equality:BVEqualityEqualTo value:@"testCategory1011"];
    [showDisplayRequest setFilterOnIncludedType:BVIncludeTypeProducts forAttribute:@"Id" equality:BVEqualityEqualTo value:@"test2"];
    [showDisplayRequest setLimit:1];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    [self waitForAnalytics];
}

-(void)testAnalyticsStatistics {
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 1;
    
    BVGet *showDisplayRequest = [[BVGet alloc] initWithType:BVGetTypeStatistics];
    [showDisplayRequest setFilterForAttribute:@"ProductId" equality:BVEqualityEqualTo values:[NSArray arrayWithObjects:@"test1", @"test2", @"test3", nil]];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeReviews];
    [showDisplayRequest addStatsOn:BVIncludeStatsTypeNativeReviews];
    [showDisplayRequest sendRequestWithDelegate:self];
    
    [self waitForAnalytics];
}

#pragma mark Recommendations Tests

//-(void)testAnalyticsRecommendations {
//    
//    numberOfExpectedImpressionAnalyticsEvents = 1;
//    numberOfExpectedPageviewAnalyticsEvents = 0; 
//    
//    BVGetShopperProfile *recs = [[BVGetShopperProfile alloc] init];
//    
//    NSString *idfaString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
//    
//    [recs fetchProductRecommendations:20 withInterest:nil withCompletionHandler:^(BVShopperProfile * _Nullable profile, NSError * _Nullable error) {
//        // completion
//        XCTAssertNil(error, @"Error should be nil: %@", error.debugDescription);
//        
//        XCTAssertNotNil(profile, @"Profile should not be nil");
//        
//        NSString *testUserId = [NSString stringWithFormat:@"magpie_idfa_%@", idfaString];
//        
//        XCTAssertTrue([profile.userId isEqualToString:testUserId], @"The profile ID and Input IDFA were not the same!");
//    }];
//    
//    [self waitForAnalytics];
//}

#pragma mark Advertising Tests

- (void)testRequestAdImpressionEvent{
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 0;
    
    BVAdsAnalyticsHelper *adsManager = [[BVAdsAnalyticsHelper alloc] init];
    
    BVAdInfo *testInfo = [[BVAdInfo alloc] initWithAdUnitId:@"/9999/autotest/banner" adType:BVBanner];
    
    [adsManager adRequested:testInfo];

    [self waitForAnalytics];
    
}

- (void)testDeliveredAdImpressionEvent{
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 0;
    
    BVAdsAnalyticsHelper *adsAnalyticsManager = [[BVAdsAnalyticsHelper alloc] init];
    
    BVAdInfo *testInfo = [[BVAdInfo alloc] initWithAdUnitId:@"/9999/autotest/banner" adType:BVBanner];
    
    [adsAnalyticsManager adDelivered:testInfo];
    
    [self waitForAnalytics];
    
}

- (void)testShowedAdImpressionEvent{
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 0;
    
    BVAdsAnalyticsHelper *adsManager = [[BVAdsAnalyticsHelper alloc] init];
    
    BVAdInfo *testInfo = [[BVAdInfo alloc] initWithAdUnitId:@"/9999/autotest/banner" adType:BVBanner];
    
    [adsManager adShown:testInfo];
    
    [self waitForAnalytics];
    
}

#pragma mark Feature Used Tests

- (void)testProductFeatureUsed{
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 0;
    
    BVProduct *testProduct = [self createFakeProduct];
    
    [BVRecsAnalyticsHelper queueAnalyticsEventForProductFeatureUsed:testProduct withFeatureUsed:TapLike];
    [BVRecsAnalyticsHelper queueAnalyticsEventForProductFeatureUsed:testProduct withFeatureUsed:TapProduct];
    [BVRecsAnalyticsHelper queueAnalyticsEventForProductFeatureUsed:testProduct withFeatureUsed:TapRatingsReviews];
    [BVRecsAnalyticsHelper queueAnalyticsEventForProductFeatureUsed:testProduct withFeatureUsed:TapShopNow];
    [BVRecsAnalyticsHelper queueAnalyticsEventForProductFeatureUsed:testProduct withFeatureUsed:TapUnlike];
    
#if ANALYTICS_STRATEGY_GET == 0
    [[BVAnalyticsManager sharedManager] flushQueue];
#endif
    
    [self waitForAnalytics];
    
}

- (void)testProductRecommendationVisible{
    
    numberOfExpectedImpressionAnalyticsEvents = 1;
    numberOfExpectedPageviewAnalyticsEvents = 0;
    
    BVProduct *testProduct = [self createFakeProduct];
    
    [BVRecsAnalyticsHelper queueAnalyticsEventForProdctView:testProduct];
    
#if ANALYTICS_STRATEGY_GET == 0
    [[BVAnalyticsManager sharedManager] flushQueue];
#endif
    
    [self waitForAnalytics];
    
}

- (BVProduct *)createFakeProduct{
    
    BVProduct *testProduct = [[BVProduct alloc] init];
    testProduct.client = @"autotestclient";
    testProduct.product_id = @"123456";
    testProduct.name = @"Auto Test Prodct";
    testProduct.client_id = @"testreseller";
    testProduct.RKB = [NSNumber numberWithInt:1];
    testProduct.RKI = [NSNumber numberWithInt:2];
    testProduct.RKP = [NSNumber numberWithInt:3];
    testProduct.RS = @"vav";
    
    return testProduct;
}


#pragma mark - BVDelegate callbacks

- (void)didReceiveResponse:(NSDictionary *)response forRequest:(id)request{
    NSLog(@"Got bv response in analytics test");
}

- (void)didFailToReceiveResponse:(NSError *)err forRequest:(id)request {
    XCTFail(@"Failed to receive response");
}

@end

