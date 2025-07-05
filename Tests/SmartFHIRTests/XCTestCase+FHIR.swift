//
//  XCTestCase+FHIR.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 8/27/14.
//  2014, SMART Health IT.
//

import XCTest
import ModelsR4
import SmartFHIR


/**
 *  Extension providing a `loadResourceData(fileName:)` method to read JSON files from disk and return a FHIR Resource.
 */
extension XCTestCase {
	
	var testResourcesDirectory: String {
		"TestResources"
	}
	
	/// Load resource FHIR Resource from a JSON file
	func loadResourceData(from fileName: String) throws -> Resource {
		let filePath = "\(testResourcesDirectory)/\(fileName)"
		guard let fileURL = Foundation.Bundle.module.url(forResource: filePath, withExtension: "json")
		else { throw TestError.failed("Cannot load test resources from: \(filePath)") }
							
		do {
			let resourceData = try Data(contentsOf: fileURL)
			return try JSONDecoder().decode(ResourceProxy.self, from: resourceData).get()
		}
		catch {
			throw TestError.failed("Cannot parse FHIR Resource from: \(filePath)")
		}
	}
	
	/// Load resource FHIR Resource from a JSON file
	func loadJsonData(from fileName: String) throws -> FHIRJSON {
		let filePath = "\(testResourcesDirectory)/\(fileName)"
		guard let fileURL = Foundation.Bundle.module.url(forResource: filePath, withExtension: "json")
		else { throw TestError.failed("Cannot load test resources from: \(filePath)") }
							
		do {
			let resourceData = try Data(contentsOf: fileURL)
			return try JSONSerialization.jsonObject(with: resourceData, options: []) as! FHIRJSON
		}
		catch {
			throw TestError.failed("Cannot parse JSON data from: \(filePath)")
		}
	}
	
}

