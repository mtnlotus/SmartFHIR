//
//  OAuthServer.swift
//  SmartFHIR
//
//  Created by David Carlson on 8/21/25.
//

public protocol OAuthServer {
	
	/// Authenticated identity and profile token of end user; Assigned when scopes `openid` and `profile` are used.
	var idToken: String? { get }
	
	/// The refresh token provided with the access token; Issuing a refresh token is optional at the discretion of the authorization server.
	var refreshToken: String? { get }
	
	/// The requested scope.
	var scope: String? { get }
	
	/// The scope actually authorized by the endpoint and user.
	var authorizedScope: String? { get }
	
}
