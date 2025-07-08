//
//  Reference+Resolve.swift
//  SmartFHIR
//
//  Created by David Carlson on 7/7/25.
//

import Foundation
import ModelsR4

extension Reference {
	
	public func resolve(using server: Server) async throws -> Resource? {
		guard let path = self.reference?.value?.string
		else { throw FHIRError.resourceReferenceNotResolved("nil").asFHIRError }
		
		return try await Resource.readFromAsync(path, server: server)
	}
	
}
