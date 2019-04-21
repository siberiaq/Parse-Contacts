//
//  Created by Alexander Borodin on 17/04/2019.
//  Copyright © 2019 Alexander Borodin. All rights reserved.
//

import Cocoa
import CSV

typealias Parameters = [String: String]

struct Tags : Codable {
    let tag : String?
    let count : Int?
    let isNew : Bool?
    let removable : Bool?
    let askReason : Bool?
    
    enum CodingKeys: String, CodingKey {
        
        case tag = "tag"
        case count = "count"
        case isNew = "isNew"
        case removable = "removable"
        case askReason = "askReason"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        tag = try values.decodeIfPresent(String.self, forKey: .tag)
        count = try values.decodeIfPresent(Int.self, forKey: .count)
        isNew = try values.decodeIfPresent(Bool.self, forKey: .isNew)
        removable = try values.decodeIfPresent(Bool.self, forKey: .removable)
        askReason = try values.decodeIfPresent(Bool.self, forKey: .askReason)
    }
}

struct result: Codable {
    let status : String?
    let message : String?
    let tags : [Tags]?
    
    enum CodingKeys: String, CodingKey {
        case status = "status"
        case message = "message"
        case tags = "tags"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decodeIfPresent(String.self, forKey: .status)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        tags = try values.decodeIfPresent([Tags].self, forKey: .tags)
    }
}

class ViewController: NSViewController {
    
    func directPhone(phone: String) -> String {
        
        var returnCSV = String()
        var toCSV = [phone]
        
        guard let url = URL(string: "http://web.getcontact.com/list-tag") else {return "Pizdec"}
        
        let parameters = [
            "hash": "df5277f7307e4378a06158607476c7ba04e69f3ee6d53b36abc3ca5f47339561",
            "phoneNumber": phone,
            "countryCode": "RU"
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = generateBoundary()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("PHPSESSID=ee32eanli0msq7qk2tu58su5hc; lang=en", forHTTPHeaderField: "Cookie")
        
        let dataBody = createDataBody(withParameters: parameters, boundary: boundary)
        request.httpBody = dataBody
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                //print(response)
            }
            
            guard let data = data else {return}
            do {
                var resultInfo = [Tags]()
                let decoder = JSONDecoder()
                let information = try decoder.decode(result.self, from: data)
                if information.status != "error" {
                    resultInfo = information.tags ?? []
                    for item in resultInfo {
                        toCSV.append(item.tag ?? "")
                    }
                    print(toCSV)
                } else {
                    print(information.message)
                }
            } catch {
                print(error)
            }
        }.resume()
        return toCSV.joined(separator:",")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var resultStr = String()
        let path  = Bundle.main.path(forResource: "numbers",ofType: "csv")
        let stream = InputStream(fileAtPath: path!)!
        let csv = try! CSVReader(stream: stream)
        
        while let row = csv.next() {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                resultStr = resultStr + self.directPhone(phone: row[0]) + "\n"
            }
        }
        
        let filename = getDocumentsDirectory().appendingPathComponent("out.csv")
        
        do {
            try resultStr.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print(error)
        }
    }
    
    func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func createDataBody(withParameters params: Parameters?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }

    override var representedObject: Any? {
        didSet {}
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
