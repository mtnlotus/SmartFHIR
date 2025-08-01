//
//  PatientListOrder.swift
//  SMART-on-FHIR
//
//  Created by Pascal Pfiffner on 2/9/15.
//  Copyright (c) 2015 SMART Health IT. All rights reserved.
//

import Foundation
import ModelsR4


/**
An enum to define how a list of patients should be ordered.
*/
public enum PatientListOrder: String {
	
	/// Order by given name, family name, birthday.
	case nameGivenASC = "given,family,birthdate"
	
	// Order by family name, given name, birthday.
	case nameFamilyASC = "family,given,birthdate"
	
	/// Order by birthdate, family name, given name.
	case birthDateASC = "birthdate,family,given"
	
	/**
	Applies the receiver's ordering to a given list of patients.
	
	- parameter patients: A list of Patient instances
	- returns: An ordered list of Patient instances
	*/
	func ordered(_ patients: [Patient]) -> [Patient] {
		switch self {
		case .nameGivenASC:
			return patients.sorted() {
				let given = $0.compareNameGiven(toPatient: $1)
				if 0 != given {
					return given < 0
				}
				let family = $0.compareNameFamily(toPatient: $1)
				if 0 != family {
					return family < 0
				}
				let birth = $0.compareBirthDate(toPatient: $1)
				return birth < 0
			}
		case .nameFamilyASC:
			return patients.sorted() {
				let family = $0.compareNameFamily(toPatient: $1)
				if 0 != family {
					return family < 0
				}
				let given = $0.compareNameGiven(toPatient: $1)
				if 0 != given {
					return given < 0
				}
				let birth = $0.compareBirthDate(toPatient: $1)
				return birth < 0
			}
		case .birthDateASC:
			return patients.sorted() {
				let birth = $0.compareBirthDate(toPatient: $1)
				if 0 != birth {
					return birth < 0
				}
				let family = $0.compareNameFamily(toPatient: $1)
				if 0 != family {
					return family < 0
				}
				let given = $0.compareNameGiven(toPatient: $1)
				return given < 0
			}
		}
	}
}


extension Patient {
	
	func compareNameGiven(toPatient: Patient) -> Int {
		let a = name?.first?.given?.first?.value?.string ?? "ZZZ"
		let b = toPatient.name?.first?.given?.first?.value?.string ?? "ZZZ"
		if a < b {
			return -1
		}
		if a > b {
			return 1
		}
		// TODO: look at other first names?
		return 0
	}
	
	func compareNameFamily(toPatient: Patient) -> Int {
		let a = name?.first?.family?.value?.string ?? "ZZZ"
		let b = toPatient.name?.first?.family?.value?.string ?? "ZZZ"
		if a < b {
			return -1
		}
		if a > b {
			return 1
		}
		// TODO: lookt at other family names?
		return 0
	}
	
	func compareBirthDate(toPatient: Patient) -> Int {
		let nodate = Date(timeIntervalSince1970: -70 * 365.25 * 24 * 3600)
		let a = (try? birthDate?.value?.asNSDate()) ?? nodate
		return a.compare((try? toPatient.birthDate?.value?.asNSDate()) ?? nodate).rawValue
	}
	
	var displayNameFamilyGiven: String {
		humanNameDisplay(name?.first) ?? "Unnamed Patient".fhir_localized
	}
	
	func humanNameDisplay(_ name: HumanName?) -> String? {
		guard let name = name else {
			return nil
		}
		
		var nm = [String]()
		name.prefix?.forEach() { nm.append($0.value?.string ?? "") }
		name.given?.forEach() { nm.append($0.value?.string ?? "") }
		if let family = name.family?.value?.string, family.count > 0 {
			nm.append(family)
		}
		name.suffix?.forEach() { nm.append($0.value?.string ?? "") }
		
		return (nm.count > 0) ? nm.joined(separator: " ") : name.text?.value?.string
	}
	
	var currentAge: String {
		guard let nsBirthDate = try? birthDate?.value?.asNSDate()
		else {
			return ""
		}
		
		let calendar = Calendar.current
		var comps = calendar.dateComponents([.year, .month], from: nsBirthDate, to: Date())
		
		// babies
		if let year = comps.year, year < 1 {
			if let month = comps.month, month < 1 {
				comps = calendar.dateComponents([.day], from: nsBirthDate, to: Date())
				if let day = comps.day, day < 1 {
					return "just born".fhir_localized
				}
				let str = (1 == comps.day) ? "day old".fhir_localized : "days old".fhir_localized
				return "\(comps.day ?? 0) \(str)"
			}
			let str = (1 == comps.day) ? "month old".fhir_localized : "months old".fhir_localized
			return "\(comps.month ?? 0) \(str)"
		}
		
		// kids and adults
		if 0 != comps.month {
			let yr = (1 == comps.year) ? "yr".fhir_localized : "yrs".fhir_localized
			let mth = (1 == comps.month) ? "mth".fhir_localized : "mths".fhir_localized
			return "\(comps.year!) \(yr), \(comps.month!) \(mth)"
		}
		
		let yr = (1 == comps.year) ? "year old".fhir_localized : "years old".fhir_localized
		return "\(comps.year!) \(yr)"
	}
}

