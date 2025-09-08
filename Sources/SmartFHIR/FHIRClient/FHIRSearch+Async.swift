//
//  FHIRSearch+Async.swift
//  SmartFHIR
//
//  Created by David Carlson on 8/11/25.
//

import ModelsR4

extension FHIRSearch {
	
	public func perform(_ server: FHIRServer) async throws -> ModelsR4.Bundle? {
		try await withCheckedThrowingContinuation { continuation in
			perform(server) { bundle, error in
				if let err = error {
					continuation.resume(throwing: err)
				}
				else {
					continuation.resume(returning: bundle)
				}
			}
		}
	}
	
}
