//
//  BVProgressiveSubmitTest.swift
//  BVSDK
//
//  Copyright © 2019 Bazaarvoice. All rights reserved.
// 

import XCTest
@testable import BVSDK

class BVProgressiveSubmitTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let configDict = ["clientId": "testcustomermobilesdk",
                          "apiKeyConversations": "cauPFGiXDMZYw1QQ11PBmJXt5YdK5oEvirFBMxlyshhlU"];
        BVSDKManager.configure(withConfiguration: configDict, configType: .staging)
        BVSDKManager.shared().setLogLevel(.verbose)
    }
    
    func testProgressiveSubmitRequestWithUserToken() {
        let expectation = self.expectation(description: "testProgressiveSubmitRequestWithUserToken")
        let submission = self.buildRequest()
        
        
        submission.submit({ (submittedReview) in
            let result = submittedReview.result
            let review = result?.review
            
            XCTAssertTrue(result?.submissionSessionToken != nil)
            XCTAssertTrue(result?.submissionId != nil)
            XCTAssertTrue(review?.rating == (submission.submissionFields["rating"] as? NSNumber))
            XCTAssertTrue(review?.title == (submission.submissionFields["title"] as? String))
            XCTAssertTrue(review?.reviewText == (submission.submissionFields["reviewText"] as? String))
            expectation.fulfill()
        }, failure: { (errors) in
            expectation.fulfill()
            print(errors)
            XCTFail()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testHostedAuthProgressiveSubmitRequest() {
        let expectation = self.expectation(description: "testHostedAuthProgressiveSubmitRequest")
        let submission = self.buildHostedAuthRequest()
        
        submission.submit({ (submittedReview) in
            let result = submittedReview.result
            let review = result?.review
            
            XCTAssertTrue(result?.submissionSessionToken != nil)
            XCTAssertTrue(result?.submissionId != nil)
            XCTAssertTrue(review?.rating == (submission.submissionFields["rating"] as? NSNumber))
            XCTAssertTrue(review?.title == (submission.submissionFields["title"] as? String))
            XCTAssertTrue(review?.reviewText == (submission.submissionFields["reviewText"] as? String))
            expectation.fulfill()
        }, failure: { (errors) in
            expectation.fulfill()
            XCTFail()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testHostedAuthProgressiveSubmitRequestMissingHostedAuthEmail() {
        let expectation = self.expectation(description: "testHostedAuthProgressiveSubmitRequestMissingHostedAuthEmail")
        let submission = self.buildHostedAuthRequest()
        submission.submissionFields.removeValue(forKey: "hostedauthentication_authenticationemail")
        
        submission.submit({ (submittedReview) in
            expectation.fulfill()
            XCTFail()
        }, failure: { (errors) in
            XCTAssertEqual(errors.count, 1)
            let error = errors.first! as NSError
            
            let errorCode = error.userInfo["BVKeyErrorCode"] as! String
            let errorMessage = error.userInfo["BVKeyErrorMessage"] as! String
            
            XCTAssertEqual(errorCode, "ERROR_PARAM_INVALID_PARAMETERS")
            XCTAssertEqual(errorMessage, "Hosted authentication callback URL and hosted authentication e-mail parameters are required when hosted authentication is enabled")
            
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testHostedAuthProgressiveSubmitRequestIncorrectUserId() {
        let expectation = self.expectation(description: "testHostedAuthProgressiveSubmitRequestIncorrectUserId")
        let submission = self.buildHostedAuthRequest()
        submission.userId = "IncorrectUserId"
        
        submission.submit({ (submittedReview) in
            expectation.fulfill()
            XCTFail()
        }, failure: { (errors) in
            XCTAssertEqual(errors.count, 1)
            let error = errors.first! as NSError
            
            let errorCode = error.userInfo["BVKeyErrorCode"] as! String
            let errorMessage = error.userInfo["BVKeyErrorMessage"] as! String
            
            XCTAssertEqual(errorCode, "ERROR_PARAM_INVALID_PARAMETERS")
            XCTAssertEqual(errorMessage, "Supplied Submission session token does not match the Review and Subject")
            
            expectation.fulfill()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressiveSubmitRequestWithFormFields() {
        let expectation = self.expectation(description: "testProgressiveSubmitRequestWithUserToken")
        let submission = self.buildRequest()
        submission.includeFields = true
        
        submission.submit({ (submittedReview) in
            let result = submittedReview.result
            let review = result?.review
            
            XCTAssertTrue(result?.submissionSessionToken != nil)
            XCTAssertTrue(result?.submissionId != nil)
            XCTAssertTrue(result?.fieldsOrder != nil)
            XCTAssertTrue(result?.formFields != nil)
            XCTAssertTrue(review?.rating == (submission.submissionFields["rating"] as? NSNumber))
            XCTAssertTrue(review?.title == (submission.submissionFields["title"] as? String))
            XCTAssertTrue(review?.reviewText == (submission.submissionFields["reviewText"] as? String))
            expectation.fulfill()
        }, failure: { (errors) in
            expectation.fulfill()
            print(errors)
            XCTFail()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressiveSubmitRequestWithPreview() {
        let expectation = self.expectation(description: "testProgressiveSubmitRequestWithUserToken")
        let submission = self.buildRequest()
        submission.isPreview = true
        
        submission.submit({ (submittedReview) in
            let result = submittedReview.result
            let review = result?.review
            
            XCTAssertTrue(result?.submissionSessionToken != nil)
            XCTAssertTrue(result?.submissionId == nil)
            XCTAssertTrue(review?.rating == (submission.submissionFields["rating"] as? NSNumber))
            XCTAssertTrue(review?.title == (submission.submissionFields["title"] as? String))
            XCTAssertTrue(review?.reviewText == (submission.submissionFields["reviewText"] as? String))
            expectation.fulfill()
        }, failure: { (errors) in
            expectation.fulfill()
            print(errors)
            XCTFail()
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressiveSubmitMissingUserEmailError() {
        let expectation = self.expectation(description: "testProgressiveSubmitMissingUserEmailError")
        let submission = self.buildRequest()
        submission.userToken = nil
        submission.userId = "tets109"
        
        submission.submit({ (submittedReview) in
            expectation.fulfill()
            XCTFail()
        }, failure: { (errors) in
            XCTAssertTrue( errors.count == 1)
            XCTAssertTrue( errors.first!.localizedDescription == "Bad Request: Email address is missing/invalid")
            expectation.fulfill()
            print(errors)
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressiveSubmitMissingUserIdError() {
        let expectation = self.expectation(description: "testProgressiveSubmitMissingUserIdError")
        let submission = self.buildRequest()
        submission.userToken = nil
        
        submission.submit({ (submittedReview) in
            expectation.fulfill()
            XCTFail()
        }, failure: { (errors) in
            
            XCTAssertTrue( errors.count == 1)
            XCTAssertTrue( errors.first!.localizedDescription == "Bad Request: UserId is missing/invalid")
            expectation.fulfill()
            print(errors)
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressiveSubmitMissingProductId() {
        let expectation = self.expectation(description: "testProgressiveSubmitMissingProductId")
        let submission = self.buildRequest()
        submission.productId = ""
        
        submission.submit({ (submittedReview) in
            expectation.fulfill()
            XCTFail()
        }, failure: { (errors) in
            XCTAssertTrue( errors.count == 1)
            XCTAssertTrue( errors.first!.localizedDescription == "Bad Request: ProductId is missing")
            expectation.fulfill()
            print(errors)
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressiveSubmitInvalidFormField() {
        let expectation = self.expectation(description: "testProgressiveSubmitInvalidFormField")
        let submission = self.buildRequest()
        submission.submissionFields["reviewText"] = "Great product"
        
        submission.submit({ (submittedReview) in
            expectation.fulfill()
            XCTFail()
        }, failure: { (errors) in
            XCTAssertTrue( errors.count == 1)
            XCTAssertTrue( errors.first!.localizedDescription == "reviewtext: ERROR_FORM_TOO_SHORT: too short")
            expectation.fulfill()
            print(errors)
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testProgressiveSubmitInvalidPasskey() {
        let expectation = self.expectation(description: "testProgressiveSubmitInvalidPasskey")
        let configDict = ["clientId": "testcustomermobilesdk",
                          "apiKeyConversations": ""];
        BVSDKManager.configure(withConfiguration: configDict, configType: .staging)
        
        let submission = self.buildRequest()
        
        submission.submit({ (submittedReview) in
            expectation.fulfill()
            XCTFail()
        }, failure: { (errors) in
            XCTAssertTrue( errors.count == 1)
            XCTAssertTrue( errors.first!.localizedDescription == "ERROR_PARAM_INVALID_API_KEY: The passKey provided is invalid.")
            expectation.fulfill()
            print(errors)
            
        })
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func buildRequest() -> BVProgressiveSubmitRequest {
        let agreedtotermsandconditions = true
        let fields: NSDictionary = [
            "rating" : 4,
            "title" : "my favorite product ever!",
            "reviewText" : "This is great its so awesome. I highly recomend using this product and think it makes a great gift for any holiday or special occasion. by far the best purchase ive made this year",
            "agreedtotermsandconditions" : agreedtotermsandconditions
        ]
        let submission = BVProgressiveSubmitRequest(productId:"product10")
        submission.submissionSessionToken = "VcticiyaPKqkXxKeZbKRoq0a3ArcQqAObHunbMNdjOiDSSYElouJV7wHkb6nZaSLw5q8OtGFyRFyPyZAChej/RAYtPmVCleQuFiwuKub0ac="
        submission.locale = "en_US"
        submission.userToken = "6b1549daa5df7eb481d8cf95c0d3e4d2646174653d3230323130363134267573657269643d746573743039383826456d61696c416464726573733d646576656c6f70657225343062617a616172766f6963652e636f6d26557365724e616d653d3039383874657374266d61786167653d333635"
        submission.submissionFields = fields as! [AnyHashable : Any]
        return submission
    }
    
    func buildHostedAuthRequest() -> BVProgressiveSubmitRequest {
        let agreedtotermsandconditions = true
        let fields: NSDictionary = [
            "rating" : 4,
            "title" : "my favorite product ever!",
            "reviewText" : "This is great its so awesome. I highly recomend using this product and think it makes a great gift for any holiday or special occasion. by far the best purchase ive made this year",
            "agreedtotermsandconditions" : agreedtotermsandconditions,
            "hostedauthentication_authenticationemail": "developer@bazaarvoice.com",
            "hostedauthentication_callbackurl": "http://apitestcustomer.bazaarvoice.com/home.html",
            "additionalfield_DateOfUserExperience": "2021-05-05"
        ]
        let submission = BVProgressiveSubmitRequest(productId:"product1")
        submission.userId = "zeygrozkxbvg01ulz5yuxzk2y3"
        submission.locale = "en_US"
        submission.submissionSessionToken = "9y8kITDlqeFpCLH634OJJvRnOcHwAsELZjOO4UT488WRz+qyogOam0P+YyZna5/CpyFK6I4XwPNAuKP7hDRBtXfkXAUp2qtGgI/GqbhcEIydQPMh9TGx8kc/8Dgn6Ik1"
        submission.submissionFields = fields as! [AnyHashable : Any]
        submission.hostedauth = true
        
        return submission
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}
