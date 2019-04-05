//
//  QuestionDisplayTests.swift
//  BVSDKTests
//
//  Copyright © 2016 Bazaarvoice. All rights reserved.
//

import XCTest
@testable import BVSDK

class QuestionDisplayTests: XCTestCase {
  
  
  override func setUp() {
    super.setUp()
    
    let configDict = ["clientId": "apitestcustomer",
                      "apiKeyConversations": "kuy3zj9pr3n7i0wxajrzj04xo"];
    BVSDKManager.configure(withConfiguration: configDict, configType: .staging)
  }
  
  
  func testQuestionDisplay() {
    
    let expectation = self.expectation(description: "")
    
    let request = BVQuestionsAndAnswersRequest(productId: "test1", limit: 10, offset: 0)
      .filter(on: .questionHasAnswers, relationalFilterOperatorValue: .equalTo, value: "true")
    
    request.load({ (response) in
      
      XCTAssertEqual(response.results.count, 10)
      
      let question = response.results.first!
      XCTAssertEqual(question.questionSummary, "Das ist mein test :)")
      XCTAssertEqual(question.questionDetails, "Das ist mein test :)")
      XCTAssertEqual(question.userNickname, "123thisisme")
      XCTAssertEqual(question.authorId, "eplz083100g")
      XCTAssertEqual(question.moderationStatus, "APPROVED")
      XCTAssertEqual(question.identifier, "14828")
      
      XCTAssertEqual(question.includedAnswers.count, 1)
      
      let answer = question.includedAnswers.first!
      XCTAssertEqual(answer.userNickname, "asdfasdfasdfasdf")
      XCTAssertEqual(answer.questionId, "14828")
      XCTAssertEqual(answer.authorId, "c6ryqeb2bq0")
      XCTAssertEqual(answer.moderationStatus, "APPROVED")
      XCTAssertEqual(answer.identifier, "16292")
      XCTAssertEqual(answer.brandImageLogoURL, nil)
      XCTAssertEqual(answer.answerText, "zxnc,vznxc osaidmf oaismdfo ims adoifmaosidmfoiamsdfimasdf")
      
      response.results.forEach { (question) in
        XCTAssertEqual(question.productId, "test1")
      }
      
      expectation.fulfill()
      
    }) { (error) in
      
      XCTFail("product display request error: \(error)")
      
    }
    
    self.waitForExpectations(timeout: 10) { (error) in
      XCTAssertNil(error, "Something went horribly wrong, request took too long.")
    }
    
  }
  
}