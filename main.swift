//
//  main.swift
//  Element-Cron-SG
//
//  Created by Sam Guzel on 16/08/2022.
//

import Foundation

/// Task:
///
/// 1) Workout how to Handle Input from Console  -- 15 mins
/// 2) Handle LHS of cat input.txt | swift main.swift HH:MM -- 30 mins
/// 3) Handle RHS HH:MM -- 30 mins
/// 4) Validation -- 25 mins --> Ran out of time
/// 5) UnitTests if have Time -- 15mins --> Ran out of time

/// handles our input parseing to
fileprivate class InputParser {
	
	public func routeInput(input: String) -> String {
		/// Now lets parse the input to our minicron class to handle the data
		do {
			return (try MiniCron.splitInput(input: input))
		} catch let error as ErrorTypes {
			print(error.description)
		} catch {
			print("Error occured, \(error)")
		}
		return "Error Occured please confirm to cat input.txt | swift main.swift HH:MM"
	}
}

private func doesInputAppearValid(input: String) -> String {
	/// Handle no input
	guard input != "" else {
		return "Please ensure to read the readme.txt for input details"
	}

	/// early protection if we're missing anything key
	if input.isEmpty, !input.contains("|"), !input.contains("cat input.txt "), !input.contains("swift main.swift") {
			return "Please Input Something in the form of 'cat input.txt | swift main.swift HH:MM'"
	}
	return input
}

fileprivate class MiniCron {
	/// cat input.txt | swift main.swift HH:MM --> Example to remember

	/// As a backup if the user doesnt provide a data / time lets use the current one
	static func GetDateNow() -> String{
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "HH:mm"
		return dateFormatter.string(from: Date())
	}
	
	/// Grab the two last two Arguments [main.swift, HH:MM]
	static func grabTimeFromInput() -> String {
		
		/// theres a chance we may not have been provided with the HH:MM so first check if we get two arguments and if not return the current time in HH:mm format
		if CommandLine.arguments.count < 2 {
			return GetDateNow()
		} else {
			/// otherwise lets return HH:MM from input
			return CommandLine.arguments[1]
		}
	}
	
	/// validation process to check if we have expected values
	static func validation(fileMinutes: String, fileHours: String, userInputMins: String, userInputHours: String) throws {
		
		/// checks the file inputs to make sure they're compliant with what we expect
		/// Hours above or equal to 0, less than 24 or include an asterix
		if !(Int(fileHours) ?? -1 >= 0 || Int(fileHours) ?? 25 < 24) || fileHours == "*" {
			throw ErrorTypes.InvalidInput
		}
		
		/// checks the file minute input to make sure they're compliant with what we expect
		/// Minutes above or equal to 0, less than 60 or include an asterix
		if !(Int(fileMinutes) ?? -1 >= 0 || Int(fileMinutes) ?? 61 < 60) || fileMinutes == "*" {
			throw ErrorTypes.InvalidInput
		}
		
		/// checks user input HH
		if !(Int(userInputHours) ?? -1 >= 0 || Int(userInputHours) ?? 25 < 24) {
			throw ErrorTypes.InvalidInput
		}
		
		/// checks user input mm
		if !(Int(userInputMins) ?? -1 >= 0 || Int(userInputMins) ?? 61 < 60) {
			throw ErrorTypes.InvalidInput
		}
		
	}
	
	/// Here we need to split the input into useable chunks
	static func splitInput(input: String) throws -> String {
		
		/// first get the time element from the file
		let getTime = grabTimeFromInput()
		
		/// Now lets break up HH:MM
		let hourMins = getTime.components(separatedBy: ":")
		/// if we couldnt do that error
		if hourMins.count < 2 {
			throw ErrorTypes.MustIncludeSemiColon
		}
		
		/// HH
		let HoursInput = hourMins[0]
		
		/// MM
		let MinutesInput = hourMins[1]
		
		/// now lets seperate out the file side of it
		/// example: ["30", "1", "/bin/run_me_daily\\"]
		let fileSideComps = input.components(separatedBy: " ")
		
		if fileSideComps.count > 3 {
			throw ErrorTypes.MustIncludeSpaces
		}
		/// seperate our three params in Minutes Hours and Bin Pat
		let minutesFromFile = fileSideComps[0]
		let hourFromFile = fileSideComps[1]
		let BinPath = fileSideComps[2]
		
		/// lets run our validation checks
		try validation(fileMinutes: minutesFromFile, fileHours: hourFromFile,userInputMins: MinutesInput,userInputHours: HoursInput)
		
		return asterixResolver(hour: HoursInput, inputFilehours: hourFromFile, minutes: MinutesInput, inputFileMinutes: minutesFromFile) + " - " + BinPath
	}
	
}
enum ErrorTypes: Error {
	case HourInputFile
	case MinutesInputFile
	case MustIncludeSemiColon
	case HourUserInput
	case InvalidInput
	case MinUserInput
	case MustIncludeSpaces
}

extension ErrorTypes: CustomStringConvertible {
	var description: String {
		switch self {
		case .MinUserInput: return "Minutes that were input did not conform to HH:mm"
		case .HourUserInput: return "Hours that were input did not conform to HH:mm"
		case .HourInputFile: return "Input file either not found or incorrect, could not get Hours"
		case .MinutesInputFile: return "Input file either not found or incorrect, could not get minutes"
		case .MustIncludeSemiColon: return "There must be a : between your HH:mm at the end of the log"
		case .MustIncludeSpaces: return "Must have spaces between the schedule components e.g Hour-space-Minutes-space-BinFile"
		case .InvalidInput: return "Minutes must be max 60, Hours must be 24 max or asterixs in the Input.txt file"
		}
	}
}


/// This is an extension for dealing with asterix's and hours/mins
extension MiniCron {
	
	/// deal with our asterix's or a mixture of asterix's and inputs, we pass in mins and hours to make the text format easier to output
	static func asterixResolver(hour: String, inputFilehours: String, minutes: String, inputFileMinutes: String) -> String {
		
		/// first deal with the easy case of both inputs having * as it basically needs to run for all
		if (inputFilehours == "*" && inputFileMinutes == "*") {
			return "\(hour):\(minutes) today"
		}
		/// Then deal with Just Hours having Asterix
		else if (inputFilehours == "*" && inputFileMinutes != "*") {
			return HourAstrix(hour: Int(hour)!, minutes: Int(minutes)!, inputFileMins: Int(inputFileMinutes)!)
			
		/// then deal with mins just having an astrix
		} else if (inputFilehours != "*" && inputFileMinutes == "*") {
			return "\(inputFilehours):00 " + MinutesAstrix(hour: Int(hour)!,inputFileHours: Int(inputFilehours)!)
			
		/// otherwise we have no astrix lets just show what we expect
		} else {
//			return "\(inputFilehours):\(inputFileMinutes) " + TimeUtils.evaluateIsTodayWithHoursAndMin(Int(hour)!, Int(inputFilehours)!, Int(minutes)!, Int(inputFileMinutes)!)
			var day = ""
			if Int(hour)! > Int(inputFilehours)! {
				day = "tomorrow"
			} else if (hour < inputFilehours){
				day = "today"
			} else {
				day = minutes > inputFileMinutes ? "tomorrow" : "today"
			}
			return "\(inputFilehours):\(inputFileMinutes) \(day)"
		}
	}
	
	/// workout the hour astrix flow i.e which hour to show and what day
	static func HourAstrix(hour: Int, minutes: Int, inputFileMins: Int) -> String {
		var returnHour = ""
		/// if we're 23 and the minutes is > inputMins return 0
		if (hour == 23 && minutes > inputFileMins) {
			returnHour = "00"
		} else if (minutes > inputFileMins){
			returnHour = String(hour+1)
		} else{
			returnHour = String(hour)
		}
		
		/// if we're past the sensible cut off lets handle moving it to the earliest next day
		let day = (hour == 23 && minutes > inputFileMins) ? "tomorrow" : "today"
		
		return returnHour + ":\(inputFileMins) " + day
	}
	
	///
	static func MinutesAstrix(hour: Int, inputFileHours: Int) -> String {
		let day = (hour > inputFileHours) ? "tomorrow" : "today"
		
		return "\(inputFileHours):00 \(day)"
	}
}

let userInput = readLine()

/// early check if our input appears valid, saves us doing logic if we spot something missing
let input = doesInputAppearValid(input: userInput ?? "")

/// if our string matches the one we put in we know we are good to continue
/// otherwise we log to customer
if input == userInput {
	print(InputParser().routeInput(input: input))
} else {
	print(input)
}
