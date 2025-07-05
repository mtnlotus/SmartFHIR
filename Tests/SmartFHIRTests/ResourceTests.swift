//
//  ResourceTests.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 27/01/16.
//  2016, SMART Health IT.
//

import XCTest
import ModelsR4
import SmartFHIR


/**
Test resource containment and `create` calls.
*/
class ResourceTests: XCTestCase {
	/*
	func testContaining() {
		let patient = Patient()
		patient.id = "subject"
		let org = Organization()
		org.id = "org"
		org.active = true
		do {
			patient.managingOrganization = try patient.contain(resource: org)
		}
		catch let error {
			XCTAssertTrue(false, "Should not raise exception \(error) when containing perfectly fine patient into order")
		}
	}
	
	func testContainingNoId() {
		let patient = Patient()
		patient.id = "subject"
		let org = Organization()
		org.active = true
		do {
			patient.managingOrganization = try patient.contain(resource: org)
			XCTAssertTrue(false, "Should have raised exception when attempting to contain resource without id")
		}
		catch {
		}
	}
	
	func testContainingItself() {
		let patient = Patient()
		patient.id = "subject"
		do {
			patient.managingOrganization = try patient.contain(resource: patient)
			XCTAssertTrue(false, "Should have raised exception when attempting to contain itself")
		}
		catch {
		}
	}
	
	// MARK: - Testing `create`
	
	func testCreate() {
		let base = URL(string: "https://api.io")!
		let server = LocalPatientServer(baseURL: base)
		
		// normal `create`
		let patient = Patient()
		patient.gender = .female
		patient.create(server) { error in
			XCTAssertNil(error)
			XCTAssertNotNil(patient.id)
			XCTAssertNil(patient.name)								// server adds POST on POST but we don't receive body data
			XCTAssertEqual("1337", patient.meta?.versionId)
			XCTAssertEqual(2016, patient.meta?.lastUpdated?.date.year)
		}
		
		// cannot do another `create` since resource has an id
		patient.create(server) { error in
			if let error = error {
				switch error {
				case FHIRError.resourceAlreadyHasId:
					break
				default:
					XCTAssertTrue(false, "Expecting `FHIRError.resourceAlreadyHasId` but got \(error)")
				}
			}
			else {
				XCTAssertTrue(false, "Expecting `FHIRError.resourceAlreadyHasId` but got nothing")
			}
		}
		
		// reset id, do another `create`
		let id = patient.id
		patient.id = nil
		patient.create(server) { error in
			XCTAssertNil(error)
			XCTAssertNotNil(patient.id)
			XCTAssertNotEqual(id, patient.id)
			XCTAssertNil(patient.name)								// server adds POST on POST but we don't receive body data
			XCTAssertEqual("1338", patient.meta?.versionId)
			XCTAssertEqual(2016, patient.meta?.lastUpdated?.date.year)
		}
		
		// configure server to do the opposite of the "Prefer" header, reset and see that the method does not care about the returned data
		server.negatePreferHeader = true
		patient.id = nil
		patient.name = nil
		patient.create(server) { error in
			XCTAssertNil(error)
			XCTAssertNotNil(patient.id)
			XCTAssertNil(patient.name)								// server adds POST on POST but we should not care
			XCTAssertEqual("1339", patient.meta?.versionId)
			XCTAssertEqual(2016, patient.meta?.lastUpdated?.date.year)
		}
	}
	
	func testCreateAndReturn() {
		let base = URL(string: "https://api.io")!
		let server = LocalPatientServer(baseURL: base)
		
		// normal `createAndReturn`
		let patient = Patient()
		patient.gender = .female
		patient.createAndReturn(server) { error in
			XCTAssertNil(error)
			XCTAssertNotNil(patient.id)
			XCTAssertNotNil(patient.name)
			XCTAssertEqual("POST", patient.name?[0].family)		// server adds this on POST and receiver must update itself
			XCTAssertEqual("1337", patient.meta?.versionId)
			XCTAssertEqual(2016, patient.meta?.lastUpdated?.date.year)
		}
		
		// cannot do another `createAndReturn` since resource has an id
		patient.createAndReturn(server) { error in
			if let error = error {
				switch error {
				case FHIRError.resourceAlreadyHasId:
					break
				default:
					XCTAssertTrue(false, "Expecting `FHIRError.resourceAlreadyHasId` but got \(error)")
				}
			}
			else {
				XCTAssertTrue(false, "Expecting `FHIRError.resourceAlreadyHasId` but got nothing")
			}
		}
		
		// reset id, do another `createAndReturn`
		let id = patient.id
		patient.id = nil
		patient.name = nil
		patient.createAndReturn(server) { error in
			XCTAssertNil(error)
			XCTAssertNotNil(patient.id)
			XCTAssertNotEqual(id, patient.id)
			XCTAssertNotNil(patient.name)
			XCTAssertEqual("POST", patient.name?[0].family)		// server adds this on POST and receiver must update itself
			XCTAssertEqual("1338", patient.meta?.versionId)
			XCTAssertEqual(2016, patient.meta?.lastUpdated?.date.year)
		}
		
		// configure server to do the opposite of the "Prefer" header, reset and see that the method accounts for the missing return
		server.negatePreferHeader = true
		patient.id = nil
		patient.name = nil
		patient.createAndReturn(server) { error in
			XCTAssertNil(error)
			XCTAssertNotNil(patient.id)
			XCTAssertNotNil(patient.name)
			XCTAssertEqual("GET", patient.name?[0].family)		// server adds this on GET after POST and receiver must update itself
			XCTAssertEqual("1339", patient.meta?.versionId)
			XCTAssertEqual(2015, patient.meta?.lastUpdated?.date.year)
		}
	}
	*/
}


/**
Stupid simple mock server that accepts POST and GET for Patient resources. Some tricks:

- sets a UUID as the resource's id on POST
- increases version on POST (starting at 1337 if there is none)
- sets the HTTP method as the first family name on the resources it returns
- sets the ETag header on GET
- sets the Last-Modified headers to "Tue, 3 May 2016 14:45:31 GMT" on POST and "Friday, 06-May-15 17:49:37 GMT" on GET
*/
class LocalPatientServer: FHIROpenServer {
	
	var negatePreferHeader = false
	
	var lastPostedResource: Resource?
	
	override func performRequest(on url: URL, handler: FHIRRequestHandler, callback: (@escaping (FHIRServerResponse) -> Void)) {
		var request = configurableRequest(for: url)
		guard let path = request.url?.path, "/Patient" == path || path.hasPrefix("/Patient/") else {
			let res = handler.notSent("Only supports Patient resources, trying to access «\(request.url?.path ?? "nil")»")
			callback(res)
			return
		}
		
		try? handler.prepare(request: &request)
		switch request.httpMethod ?? "GET" {
		
		case "POST":
			let version = Int(handler.resource?.meta?.versionId?.value?.string ?? "1336")!
			let location = "\(self.baseURL.absoluteString)Patient/\(UUID().uuidString)/_history/\(version+1)"
			let headers = ["Location": location, "Last-mODified": "Tue, 3 May 2016 14:45:31 GMT"]
			let http = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "1.1", headerFields: headers)
			
			let prefer = request.allHTTPHeaderFields?["Prefer"] ?? "minimal"
			if prefer.hasSuffix("representation") != negatePreferHeader {
				// do not manipulate handler.resource
				let data = try! JSONSerialization.data(withJSONObject: handler.resource!.asJSON())
				let pat = try! JSONDecoder().decode(Patient.self, from: data)
				
				pat.meta?.versionId = FHIRString("\(version+1)").asPrimitive()
				pat.name = [HumanName(family: "POST")]
				
				let req = FHIRJSONRequestHandler(.POST)
				req.resource = pat
				try! req.prepareData()
				
				callback(handler.response(response: http, data: req.data, error: nil))
			}
			else {
				callback(handler.response(response: http, data: nil, error: nil))
			}
			lastPostedResource = handler.resource
		
		case "GET":
			if let last = lastPostedResource as? Patient {
				let version = last.meta?.versionId?.value?.string ?? "1339"
				let headers = ["ETag": "W/\"\(version)\"", "Last-Modified": "Friday, 06-May-15 17:49:37 GMT"]
				let http = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: headers)
				
				last.name = [HumanName(family: "GET")]
				last.meta = nil
				
				let req = FHIRJSONRequestHandler(.GET)
				req.resource = last
				try! req.prepareData()
				
				callback(handler.response(response: http, data: req.data, error: nil))
			}
			else {
				callback(handler.notSent("\(String(describing: request.httpMethod)) without preceding “POST” is not supported"))
			}
		
		default:
			callback(handler.notSent("\(String(describing: request.httpMethod)) is not yet supported"))
		}
	}
}

