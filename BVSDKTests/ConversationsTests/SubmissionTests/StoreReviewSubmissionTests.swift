//
//  ConversationsSubmissionTests.swift
//  BVSDKTests
//
//  Copyright © 2016 Bazaarvoice. All rights reserved.
//


import XCTest
@testable import BVSDK

class StoreReviewSubmissionTests: BVBaseStubTestCase {
  
  override func setUp() {
    super.setUp()
    let configDict = ["clientId": "apiunittests",
                      "apiKeyConversationsStores": "2cpdrhohmgmwfz8vqyo48f52g"];
    BVSDKManager.configure(withConfiguration: configDict, configType: .staging)
    BVSDKManager.shared().setLogLevel(.error)
  }
  
  func testSubmitStoreReviewWithPhoto() {
    
    let expectation = self.expectation(description: "testSubmitStoreReviewWithPhoto")
    
    let sequenceFiles:[String] =
      [
        "testSubmitStoreReviewWithPhoto.json"
    ]
    stub(withJSONSequence: sequenceFiles)
    
    let review = self.fillOutReview()
    review.submit({ (reviewSubmission) in
      expectation.fulfill()
    }, failure: { (errors) in
      XCTFail()
      expectation.fulfill()
    })
    
    waitForExpectations(timeout: 10, handler: nil)
  }
  
  func testSubmitReviewFailureStore() {
    let expectation = self.expectation(description: "testSubmitReviewFailureStore")
    
    let sequenceFiles:[String] =
      [
        "testSubmitReviewFailureStore.json"
    ]
    stub(withJSONSequence: sequenceFiles)
    
    let review = BVStoreReviewSubmission(reviewTitle: "", reviewText: "", rating: 123, storeId: "1000001")
    review.userNickname = "cgil"
    review.userId = "craiggiddll"
    review.action = .submit
    
    review.submit({ (reviewSubmission) in
      //XCTFail()
      expectation.fulfill()
    }, failure: { (errors) in
      errors.forEach { print("Expected Failure Item: \($0)") }
      XCTAssertEqual(errors.count, 4)
      expectation.fulfill()
    })
    waitForExpectations(timeout: 10, handler: nil)
  }
  
  func fillOutReview() -> BVStoreReviewSubmission {
    let review = BVStoreReviewSubmission(reviewTitle: "The best store ever!",
                                         reviewText: "The store has some of the friendliest staff, and very knowledgable!",
                                         rating: 5,
                                         storeId: "1")
    
    let randomId = String(arc4random())
    
    review.locale = "en_US"
    review.sendEmailAlertWhenCommented = true
    review.sendEmailAlertWhenPublished = true
    review.userNickname = "UserNickname" + randomId
    review.userId = "userField" + randomId
    review.netPromoterScore = 5
    review.userEmail = "developer@bazaarvoice.com"
    review.agreedToTermsAndConditions = true
    review.action = .preview
    
    review.addContextDataValueBool("VerifiedPurchaser", value: false)
    review.addContextDataValueString("Age", value: "18to24")
    review.addContextDataValueString("Gender", value: "Male")
    review.addRatingQuestion("Cleanliness", value: 1)
    review.addRatingQuestion("HelpfullNess", value: 3)
    review.addRatingQuestion("Inventory", value: 4)
    
    return review
  }
}
