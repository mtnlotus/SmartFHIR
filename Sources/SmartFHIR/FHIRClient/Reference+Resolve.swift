//
//  Reference+Resolve.swift
//  SmartFHIR
//
//  Created by David Carlson on 7/7/25.
//

import Foundation
import ModelsR4

extension Reference {
	
	public func resolve<T: Resource>(using server: Server, ofType: T.Type) async throws -> T? {
		guard let path = self.reference?.value?.string
		else { throw FHIRError.resourceReferenceNotResolved("nil").asFHIRError }
		
		return try await ofType.readFromAsync(path, server: server)
	}
	
	public func relativeReference() -> String? {
		guard var path = self.reference?.value?.string
		else { return nil }
		
		var parts = path.split(separator: "/")
		if parts.count == 2 {
			return path
		}
		else if parts.count > 2, let id = parts.popLast(), let resourceType = parts.popLast() {
			return "\(resourceType)/\(id)"
		}
		return nil
	}
}
