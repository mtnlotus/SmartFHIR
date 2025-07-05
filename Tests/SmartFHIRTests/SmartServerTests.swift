//
//  ServerTests.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 6/23/14.
//  2014, SMART Health IT.
//

import XCTest
import ModelsR4

@testable
import SmartFHIR


class SmartServerTests: XCTestCase {
	
	func testMetadataParsing() throws {
		let server = Server(baseURL: URL(string: "https://r4.smarthealthit.org")!)
		XCTAssertEqual("https://r4.smarthealthit.org/", server.baseURL.absoluteString)
		XCTAssertEqual("https://r4.smarthealthit.org", server.aud)
		
		let capabilityStatement = try loadResourceData(from: "metadata.full") as! CapabilityStatement
		XCTAssertNotNil(capabilityStatement, "Should parse `metadata`")
		
		server.capability = capabilityStatement
		XCTAssertNotNil(server.capability, "Should store all metadata")
    }
	
	@MainActor func testMetadataAuth() {
		// Epic R4 sandbox
		let server = Server(baseURL: URL(string: "https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4/")!)
		
		
		let exp2 = self.expectation(description: "Metadata fetch expectation 2")
		server.getCapabilityStatement() { error in
			XCTAssertNil(error, "Expecting filesystem-fetching to succeed")
			XCTAssertNotNil(server.auth, "Server is OAuth2 protected, must have `Auth` instance")
			
			if let auth = server.auth {
				XCTAssertTrue(auth.type == AuthType.codeGrant, "Should use code grant auth type, not \(server.auth!.type.rawValue)")
				XCTAssertNotNil(auth.settings, "Server `Auth` instance must have settings dictionary")
				XCTAssertNotNil(auth.settings?["token_uri"], "Must read token_uri")
				XCTAssertEqual(auth.settings?["token_uri"] as? String, "https://fhir.epic.com/interconnect-fhir-oauth/oauth2/token", "token_uri must be “https://fhir.epic.com/interconnect-fhir-oauth/oauth2/token”")
			}
			exp2.fulfill()
		}
		
		waitForExpectations(timeout: 20, handler: nil)
	}
}

