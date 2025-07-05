//
//  FHIRAbstractBase.swift
//  SmartFHIR
//
//  Created by David Carlson on 7/1/25.
//

import ModelsR4

public protocol FHIRAbstractBase {
	
	/// A specific version id, if the instance was created using `vread`.
	var _versionId: String? { get set }
	
	/// If this instance lives on a server, this property represents that server.
	var _server: FHIRServer? { get set }
	
	var __server: FHIRServer? { get set }
	
}

extension Resource: FHIRAbstractBase {
	
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
	
}
