//
//  FHIRServerResponse.swift
//  SwiftFHIR
//
//  Created by Pascal Pfiffner on 3/31/15.
//  2015, SMART Platforms.
//

import Foundation
import ModelsR4


extension FHIRServerResponse {
	
	/**
	The base implementation inspects response headers ("Location", "Last-Modified" and "ETag") and updates the resource's `id` and `meta`
	accordingly.
	
	This method must not be called if the response has a non-nil error.
	
	- parameter resource: The resource to apply response data to
	*/
	public func applyHeaders(to resource: Resource) throws {
		
		// inspect Location header to update `id` and `meta`. It has the form "Location: [base]/[type]/[id]/_history/[vid]"
		if let location = headers["Location"] {
			if let base = resource._server?.baseURL.absoluteString {    // we are able to rely on the fact that the base URL ends with "/"
				if location.hasPrefix(base) {
					let path = location.replacingOccurrences(of: base, with: "")
					let components = path.components(separatedBy: "/")
					guard components.count > 1 && type(of: resource).resourceType.rawValue == components[0] else {
						throw FHIRError.responseLocationHeaderResourceTypeMismatch(location, type(of: resource).resourceType.rawValue)
					}
					
					resource.id = FHIRString(components[1]).asPrimitive()
					if components.count > 3 && "_history" == components[2] {
						resource.meta = resource.meta ?? Meta()
						resource.meta!.versionId = FHIRString(components[3]).asPrimitive()
					}
				}
				else {
					fhir_warn("Location “\(location)” does not appear to live on server \(base), not updating the resource")
				}
			}
			else {
				fhir_warn("Resource «\(resource)» does not have a server associated, will not try to parse “Location” header")
			}
		}
		
		// inspect Last-Modified header
		if let modified = headers["Last-Modified"] {
			resource.meta = resource.meta ?? Meta()
			resource.meta!.lastUpdated = try? Instant(modified).asPrimitive()
		}
		
		// inspect ETag header
		if var etag = headers["ETag"] {
			if etag.hasPrefix("W/") {
				etag = String(etag[etag.index(etag.startIndex, offsetBy: 2)..<etag.endIndex])
			}
			if etag.hasPrefix("\"") {
				etag = String(etag[etag.index(etag.startIndex, offsetBy: 1)..<etag.endIndex])
			}
			if etag.hasSuffix("\"") {
				etag = String(etag[etag.startIndex..<etag.index(etag.endIndex, offsetBy: -1)])
			}
			resource.meta = resource.meta ?? Meta()
			resource.meta!.versionId = FHIRString(etag).asPrimitive()
		}
	}
	
	/// Nicely format status code, response headers and response body (if any).
	public var debugDescription: String {
		var msg = "HTTP 1.1 \(status)"
		headers.forEach() { msg += "\n\($0): \($1)" }
		if let body = body, body.count > 0 {
			msg += "\n\n\(NSString(data: body as Data, encoding: String.Encoding.utf8.rawValue) ?? "")"
		}
		return msg
	}
}


/**
Encapsulates a server response, which can also indicate that there was no response or not even a request, in which case the `error`
property carries the only useful information.
*/
open class FHIRServerDataResponse: FHIRServerResponse {
	
	/// The handler handling the request provoking this response.
	public internal(set) var handler: FHIRRequestHandler?
	
	/// The HTTP status code.
	public let status: Int
	
	/// Response headers.
	public let headers: [String: String]
	
	/// The response body data.
	open var body: Data?
	
	/// The request's operation outcome, if any.
	public internal(set) var outcome: OperationOutcome?
	
	/// The error encountered, if any.
	open var error: FHIRError?
	
	/**
	Instantiate a FHIRServerResponse from a (HTTP)URLResponse, Data and an optional Error.
	*/
	public required init(handler: FHIRRequestHandler, response: URLResponse, data: Data?, error: Error?) {
		var status = 0
		var headers = [String: String]()
		
		// parse status and headers from the URL response
		if let http = response as? HTTPURLResponse {
			status = http.statusCode
			for (key, val) in http.allHeaderFields {
				if let keystr = key as? String {
					if let valstr = val as? String {
						headers[("Etag" == keystr) ? "ETag" : keystr] = valstr		// NSHTTPURLResponse returns "Etag"
					}
					else {
						fhir_warn("Not a string in headers: \(val) (for \(keystr))")
					}
				}
			}
		}
		
		// was there an error?
		if let error = error, NSURLErrorDomain == error._domain {
			self.error = FHIRError.requestError(status, error.humanized)
		}
		else if let error = error as? FHIRError {
			self.error = error
		}
		else if let error = error {
			self.error = FHIRError.error(error.localizedDescription)
		}
		
		self.handler = handler
		self.status = status
		self.headers = headers
		self.body = data
	}
	
	public required init(error: Error, handler: FHIRRequestHandler? = nil) {
		self.handler = handler
		self.status = 0
		self.headers = [String: String]()
		if NSURLErrorDomain == error._domain {
			self.error = FHIRError.requestError(status, error.humanized)
		}
		else if let error = error as? FHIRError {
			self.error = error
		}
		else {
			self.error = FHIRError.error("\(error)")
		}
	}
	
	
	// MARK: - Responses
	
	/**
	The base method does not know how to extract a response resource, so this will throw `FHIRError.responseNoResourceReceived`.
	
	- parameter type: The response resource's type
	- returns: An instance of the expected type
	*/
	open func responseResource<T: Resource>(ofType: T.Type) throws -> T {
		throw FHIRError.responseNoResourceReceived
	}
	
	/**
	The base method does not actually know how to handle the data to update a resource, but it will still throw
	`FHIRError.ResponseNoResourceReceived` if body is nil.
	
	- parameter to: The resource to apply the response data to
	*/
	open func applyBody(to: Resource) throws {
		guard nil != body else {
			throw FHIRError.responseNoResourceReceived
		}
	}
}


/**
Encapsulates a server response with JSON response body, if any.
*/
open class FHIRServerJSONResponse: FHIRServerDataResponse {
	
	/// The response body, decoded into a FHIRJSON
	open var json: FHIRJSON?
	
	/**
	If the status is >= 400, the response body is checked for an OperationOutcome and its first issue item is turned into an error message.
	*/
	public required init(handler: FHIRRequestHandler, response: URLResponse, data inData: Data?, error: Error?) {
		super.init(handler: handler, response: response, data: inData, error: error)
		
		// parse data as JSON
		if let data = inData, data.count > 0 {
			do {
				json = try JSONSerialization.jsonObject(with: data, options: []) as? FHIRJSON
			}
			catch let error as NSError {
				// Cocoa error 3840 is JSON parsing error; some error responses may not return JSON, don't report an error on those
				if 3840 != error.code || NSCocoaErrorDomain != error.domain || status < 400 {
					let raw = String(data: data, encoding: String.Encoding.utf8) ?? ""
					self.error = FHIRError.jsonParsingError(error.localizedDescription, raw)
				}
			}
			catch let error {
				self.error = error.asFHIRError
			}
		}
		
		// fill error on HTTP status >= 400
		if status >= 400 {
			do {
				// TODO: be smarter as to when to expect an operation outcome; may also be returned if < 400
				self.outcome = try responseResource(ofType: OperationOutcome.self)
			}
			catch {  }
			if nil == outcome {
				fhir_warn("No OperationOutcome available")
			}
			if let erritem = self.outcome?.issue.first {
				let errstr = "[\(erritem.severity.value?.rawValue ?? "unknown")] \(erritem.diagnostics ?? "unknown")"
				self.error = FHIRError.requestError(status, errstr)
			}
			else if let errstr = json?["error"] as? String {
				self.error = FHIRError.requestError(status, errstr)
			}
			else {
				var errstr = "Error"
				if let urlResponse = response as? HTTPURLResponse {
					errstr = HTTPURLResponse.localizedString(forStatusCode: urlResponse.statusCode)
				}
				self.error = FHIRError.requestError(status, errstr)
			}
		}
	}
	
	public required init(error: Error, handler: FHIRRequestHandler? = nil) {
		super.init(error: error, handler: handler)
	}
	
	/**
	Uses FHIRElement's factory method to instantiate the resource of the given type from the response.
	
	- parameter ofType: The type of resource to extract
	- returns:          The resource that was found in the response if it is of the desired type
	- throws:           Errors if there was no response, if it was of a different type or if there were errors in the data
	*/
	override open func responseResource<T: Resource>(ofType: T.Type) throws -> T {
		guard let json = json else {
			throw FHIRError.responseNoResourceReceived
		}
		let decoder = JSONDecoder()
		let data = try JSONSerialization.data(withJSONObject: json, options: [])
		let resource = try decoder.decode(ofType, from: data)
		
		return resource
	}
	
}


// MARK: -

extension Error {
	
	/**
	Return a human-readable, localized string for error codes of the NSURLErrorDomain. Will simply return `localizedDescription` for if the
	receiver is not of that domain.
	
	The list of errors that are "humanized" is not necessarily exhaustive. All strings are returned `fhir_localized`.
	*/
	public var humanized: String {
		guard NSURLErrorDomain == _domain else {
			return localizedDescription
		}
		switch _code {
		case NSURLErrorBadURL:                return "The URL was malformed".fhir_localized
		case NSURLErrorTimedOut:              return "The connection timed out".fhir_localized
		case NSURLErrorUnsupportedURL:        return "The URL scheme is not supported".fhir_localized
		case NSURLErrorCannotFindHost:        return "The host could not be found".fhir_localized
		case NSURLErrorCannotConnectToHost:   return "A connection to the host cannot be established".fhir_localized
		case NSURLErrorNetworkConnectionLost: return "The network connection was lost".fhir_localized
		case NSURLErrorDNSLookupFailed:       return "The connection failed because the DNS lookup failed".fhir_localized
		case NSURLErrorHTTPTooManyRedirects:  return "The HTTP connection failed due to too many redirects".fhir_localized
		default:                              return localizedDescription
		}
	}
}

