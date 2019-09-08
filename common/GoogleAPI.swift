//
//  GoogleAPI.swift
//  worktime
//
//  Created by junha on 2019/09/05.
//  Copyright © 2019 heek.kr. All rights reserved.
//

import Moya


enum GoogleAPI {
    case refreshToken(clientID: String, refreshToken: String)
    case userCalendarList
    case createEvent(calendarID: String, event: Event)
}

extension GoogleAPI: TargetType {
    var baseURL: URL {
        return URL(string: "https://www.googleapis.com")!
    }

    var path: String {
        switch self {
        case .refreshToken:
            return "/oauth2/v4/token"
        case .userCalendarList:
            return "/calendar/v3/users/me/calendarList"
        case let .createEvent(calendarID, _):
            return "/calendar/v3/calendars/\(calendarID)/events"
        }
    }

    var method: Method {
        switch self {
        case .userCalendarList:
            return .get
        case .refreshToken, .createEvent:
            return .post
        }
    }

    var sampleData: Data {
        switch self {
        case .userCalendarList:
            return """
            {
                "items": [
                    {"id": "근무시간", "summary": "근무시간"},
                    {"id": "휴가", "summary": "휴가"},
                    {"id": "공휴일", "summary": "공휴일"},
                    {"id": "Meeting", "summary": "Meeting"}
                ]
            }
            """.utf8Encoded
        case .refreshToken:
            return """
            {
                "access_token": "MOCK-REFRESHED-ACCESS-TOKEN",
                "expires_in": "3600",
                "token_type": "bearer"
            }
            """.utf8Encoded
        default:
            return "{}".utf8Encoded
        }
    }

    var task: Task {
        switch self {
        case let .refreshToken(clientID, refreshToken):
            return .requestParameters(
                parameters: [
                    "client_id": clientID,
                    "refresh_token": refreshToken,
                    "grant_type": "refresh_token"
                ],
                encoding: URLEncoding.default
            )
        case .userCalendarList:
            return .requestPlain
        case let .createEvent(_, event):
            return .requestJSONEncodable(event)
        }
    }

    var headers: [String: String]? {
        switch self {
        case .refreshToken:
            return [:]
        default:
            return ["Content-Type": "application/json"]
        }
    }
}

extension GoogleAPI: AccessTokenAuthorizable {
    var authorizationType: AuthorizationType {
        switch self {
        case .refreshToken:
            return .none
        case .userCalendarList, .createEvent:
            return .bearer
        }
    }
}


// MARK: Resources

struct Token: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType: String

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

struct CalendarList: Codable {
    let items: [CalendarListEntry]
    let nextPageToken: String?

    private enum CodingKeys: String, CodingKey {
        case items
        case nextPageToken
    }
}

struct CalendarListEntry: Codable {
    let id: String
    let summary: String
    let description: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case summary
        case description
    }
}

struct Event: Codable {
    let id: String?

    let summary: String
    let start: EventTime  // (Inclusive)
    let end: EventTime  // (Exclusive)

    private enum CodingKeys: String, CodingKey {
        case id
        case summary
        case start
        case end
    }
}

enum EventTime: Codable {
    case date(Date)
    case dateTime(Date)

    private enum CodingKeys: String, CodingKey {
        case date
        case dateTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let date = try? container.decode(String.self, forKey: .date) {
            self = .date(Date())  // TODO:
            return
        }

        if let dateTime = try? container.decode(String.self, forKey: .dateTime), let value = dateTime.date {
            self = .dateTime(value)
            return
        }

        throw DecodingError.dataCorruptedError(
            forKey: .date,  // FIXME:
            in: container,
            debugDescription: "One of `date` or `datetime` must given"
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .date(date):
            try container.encode("", forKey: .date)  // TODO:
        case let .dateTime(dateTime):
            try container.encode(dateTime.isoFormat, forKey: .dateTime)
        }
    }
}
