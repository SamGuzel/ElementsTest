//
//  UnitTests.swift
//  UnitTests
//
//  Created by Sam Guzel on 18/08/2022.
//

import XCTest

class UnitTests: XCTestCase {
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	private func inputText(fileInput: String, userInput: [String]) -> [String] {
		do {
			let bundle = Bundle(for: type(of: self))
			let resource = fileInput.split(separator: ".")
			let path = bundle.path(forResource: "\(resource[0])", ofType: "\(resource[1])")!
			let stringData = try String(contentsOfFile: path)
			let stringByLine = stringData.split(whereSeparator: \.isNewline)
			
			var output: [String] = []
			for string in stringByLine {
				
				let fileOutput = fileInput.replacingOccurrences(of: "input.txt", with: "\(string)")

				/// initiate our inputs
				CommandLine.arguments = userInput
					/// early check if our input appears valid, saves us doing logic if we spot something missing
					let input = doesInputAppearValid(input: fileOutput)
					
					/// if our string matches the one we put in we know we are good to continue
					/// otherwise we log to customer
					output.append(InputParser().routeInput(input: input))
					
			}
			return output
			
		} catch {
			return(["Error"])
		}
	}
	
	func testSuccess() throws {
		let userInput = ["swift main.swift", "01:31"]
		let output = inputText(fileInput: "input.txt", userInput: userInput)
		
		for log in output {
			XCTAssert(!log.contains("Error"), "Output should not contain Error")
		}
	}
	
	func testMissingSemiColon() throws {
		let userInput = ["swift main.swift", "1610"]
		let output = inputText(fileInput: "input.txt", userInput: userInput)
		
		for log in output {
			XCTAssert(log.contains("Error"), "Output contain Error")
		}
	}
	
	func testMissingTimeWorks() throws {
		let userInput = ["swift main.swift"]
		let output = inputText(fileInput: "input.txt", userInput: userInput)
		
		for log in output {
			XCTAssert(!log.contains("Error"), "Output should not contain Error")
		}
	}
	
	func testNoFileTime() throws {
		let userInput = ["swift main.swift", "16:10"]
		let output = inputText(fileInput: "inputMissingTime.txt", userInput: userInput)
		
		for log in output {
			XCTAssert(log.contains("Error"), "Output contain Error")
		}
	}
	
	func testOutputSuccess() throws {
		let userInput = ["swift main.swift", "16:20"]
		let output = inputText(fileInput: "input.txt", userInput: userInput)
		
		let log1 = "1:30 tomorrow - /bin/run_me_daily"
		let log2 = "16:45 today - /bin/run_me_hourly"
		let log3 = "16:20 today - /bin/run_me_every_minute"
		let log4 = "19:00 today - /bin/run_me_sixty_times"
		let logList = [log1, log2, log3, log4]
		
		var i = 0
		for log in output {
			XCTAssert(!log.contains("Error"), "Output doesnt contain an Error")
			XCTAssert(log.contains(logList[i]), "Output is as expected")
			i += 1
		}
	}
	
	func testAfterTimeDisplaysTomorrow() throws {
		let userInput = ["swift main.swift", "1:29"]
		let output = inputText(fileInput: "input.txt", userInput: userInput)
		
		let userInput1 = ["swift main.swift", "1:31"]
		let output1 = inputText(fileInput: "input.txt", userInput: userInput1)
		
		let log1 = "1:30 today - /bin/run_me_daily"
		let log2 = "1:30 tomorrow - /bin/run_me_daily"
		

		let log = output[0]
		XCTAssert(!log.contains("Error"), "Output doesnt contain an Error")
		XCTAssert(log.contains(log1), "Output is as expected")
		
		let logTomorrow = output1[0]
		XCTAssert(!logTomorrow.contains("Error"), "Output doesnt contain an Error")
		XCTAssert(logTomorrow.contains(log2), "Output is as expected")
	}
}
