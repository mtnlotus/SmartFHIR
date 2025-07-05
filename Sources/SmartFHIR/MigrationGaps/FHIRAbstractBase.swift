//
//  FHIRAbstractBase.swift
//  SmartFHIR
//
//  Created by David Carlson on 7/1/25.
//

import Foundation
import ModelsR4

//public protocol FHIRAbstractBase: FHIRJSONType where JSONType == FHIRJSON {
public protocol FHIRAbstractBase {
	
	/// The JSON element used to deserialize the receiver from and serialize to.
	associatedtype JSONType
	
	/// A specific version id, if the instance was created using `vread`.
	var _versionId: String? { get set }
	
	/// If this instance lives on a server, this property represents that server.
	var _server: FHIRServer? { get set }
	
	var __server: FHIRServer? { get set }
	
}

extension Resource: FHIRAbstractBase {
	
	public typealias JSONType = FHIRJSON
	
	public var _versionId: String? {
		get { return nil }
		set { }
	}
	
	/// If this instance lives on a server, this property represents that server.
	public var _server: FHIRServer? {
		get { return nil }
		set { }
		
//		get { return __server ?? _owningResource?._server }
//		set { __server = newValue }
	}
	
	public var __server: FHIRServer? {
		get { return nil }
		set { }
	}
	
	public func decorate(json: inout FHIRJSON, withKey: String, errors: inout [FHIRValidationError]) {
		// Not used with FHIRModels
	}
	
	public var _owner: (any FHIRAbstractBase)? {
		get {
			return nil
		}
		set {
			// Not used with FHIRModels
		}
	}
	
}

extension Resource {
	
	/**
	Represent the receiver in FHIRJSON, ready to be used for JSON serialization.
	
	- returns: The FHIRJSON reperesentation of the receiver
	*/
	public final func asJSON() throws -> JSONType {
		var errors = [FHIRValidationError]()
		let json = asJSON(errors: &errors)
		if !errors.isEmpty {
			throw FHIRValidationError(errors: errors)
		}
		return json
	}
	
	/**
	Represent the receiver in FHIRJSON, ready to be used for JSON serialization. Non-throwing version that you can use if you want to handle
	errors yourself or ignore them altogether. Otherwise, just use `asJSON() throws`.
	
	- parameter errors: The array that will be filled with FHIRValidationError instances, if there are any
	- returns: The FHIRJSON reperesentation of the receiver
	*/
	public final func asJSON(errors: inout [FHIRValidationError]) -> JSONType {
		var json = FHIRJSON()
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
		do {
			let data = try encoder.encode(self)
			if let rawDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
				json = rawDict
			}
			
		} catch {
			errors.append(FHIRValidationError(missing: "Failed to encode into JSON: \(error)"))
		}
		
// TODO:
//		decorate(json: &json, errors: &errors)
		return json
	}
}
