//
//  Session.swift
//  botsecretobot
//
//  Created by Wellington Nascente Hirsch on 01/09/21.
//

import Foundation
import TelegramBotSDK

class Session {
    private var users: [User] = []
    private var blockedMatches: [(User, User)] = []
    private var userMatches: [(User, User)] = []
    private var userGetDMs: [Int64: Int64] = [:]
    private var userGiveDMs: [Int64: Int64] = [:]
    private var wasPlayedFunction: Bool = false
    
    var wasPlayed: Bool {
        return wasPlayedFunction && userMatches.count == users.count
    }
    
    var listString: String {
        var desc = "\("users_participating".localized)\n"
        
        if users.isEmpty {
            desc.append("\("no_users".localized)\n")
        } else {
            for user in users {
                desc.append(user.firstName)
                if let lastName = user.lastName {
                    desc.append(" \(lastName)")
                }
                if let username = user.username {
                    desc.append(" - @\(username)")
                }
                desc.append("\n")
            }
        }
        
        desc.append("\n\("users_not_match".localized)\n")
        if blockedMatches.isEmpty {
            desc.append("\("no_users".localized)\n")
        } else {
            for pair in blockedMatches {
                desc.append(pair.0.firstName)
                if let username = pair.0.username {
                    desc.append(" @\(username)")
                }
                desc.append(" - \(pair.1.firstName)")
                if let username = pair.1.username {
                    desc.append(" @\(username)")
                }
                desc.append("\n")
            }
        }
        
        return desc
    }
    
    func userExists(userId: Int64) -> Bool {
        return users.contains(where: { $0.id == userId })
    }
    
    func getUserToGet(userId: Int64) -> User? {
        guard wasPlayed else { return nil }
        return userMatches.first(where: { $0.1.id == userId })?.0
    }
    
    func getUserToGive(userId: Int64) -> User? {
        guard wasPlayed else { return nil }
        return userMatches.first(where: { $0.0.id == userId })?.1
    }
    
    func getUserToGetDM(userId: Int64) -> Int64? {
        guard let userToGet = getUserToGet(userId: userId) else { return nil }
        return self.userGiveDMs[userToGet.id]
    }
    
    func getUserToGiveDM(userId: Int64) -> Int64? {
        guard let userToGive = getUserToGive(userId: userId) else { return nil }
        return self.userGetDMs[userToGive.id]
    }
    
    func addUserGetDM(userId: Int64, chatId: Int64) {
        self.userGetDMs[userId] = chatId
    }
    
    func addUserGiveDM(userId: Int64, chatId: Int64) {
        self.userGiveDMs[userId] = chatId
    }
    
    func addUser(newUser: User) -> Bool {
        if !newUser.isBot, self.users.firstIndex(where: { $0.id == newUser.id }) == nil {
            self.users.append(newUser)
            return true
        }
        return false
    }
    
    func removeUser(user: User) -> Bool {
        if let index = self.users.firstIndex(where: { $0.id == user.id }) {
            self.users.remove(at: index)
            return true
        }
        return false
    }
    
    func addBlock(userA: String, userB: String) -> Bool {
        guard userA != userB else { return false }
        guard !blockedMatches.contains(where: { ($0.0.username == userA && $0.1.username == userB) || ($0.0.username == userB && $0.1.username == userA) }) else { return false }
        
        if let userAObj = users.first(where: { $0.username == userA }), let userBObj = users.first(where: { $0.username == userB }) {
            self.blockedMatches.append((userAObj, userBObj))
            return true
        }
        
        return false
    }
    
    func removeBlock(userA: String, userB: String) -> Bool {
        guard userA != userB else { return false }
        
        if let index = self.blockedMatches.firstIndex(
            where: { ($0.0.username == userA && $0.1.username == userB) || ($0.0.username == userB && $0.1.username == userA) }) {
            self.blockedMatches.remove(at: index)
            return true
        }
        
        return false
    }
    
    func play() -> Bool {
        guard users.count > 1 else { return false }

        let shuffledUsers = users.shuffled()
        var possiblePairs: [[Int]] = Array(repeating: Array(repeating: 1, count: users.count), count: users.count)

        for index in 0..<shuffledUsers.count {
            possiblePairs[index][index] = 0
        }

        for blockedMatch in blockedMatches {
            guard let userAIndex = shuffledUsers.firstIndex(where: { $0.id == blockedMatch.0.id }),
                  let userBIndex = shuffledUsers.firstIndex(where: { $0.id == blockedMatch.1.id }) else { continue }
            possiblePairs[userAIndex][userBIndex] = 0
            possiblePairs[userBIndex][userAIndex] = 0
        }

        let matches = computePairs(possiblePairs, size: possiblePairs.count)
        if matches.count == shuffledUsers.count {
            for match in matches {
                userMatches.append((shuffledUsers[match.0], shuffledUsers[match.1]))
            }
            self.wasPlayedFunction = true
            return true
        }

        return false
    }
    
    private func computePairs(_ possiblePairs: [[Int]], size: Int) -> [Int: Int] {
        guard size > 0 else { return [:] }
        
        var minPossibilities = possiblePairs[0].reduce(0, +)
        var minIndex = 0
        for index in 1..<possiblePairs.count {
            let actualPossibilities = possiblePairs[index].reduce(0, +)
            if actualPossibilities < minPossibilities {
                minPossibilities = actualPossibilities
                minIndex = index
            }
        }
        
        for index in 0..<possiblePairs[minIndex].count {
            guard possiblePairs[minIndex][index] == 1 else { continue }
            
            var auxPossiblePairs = possiblePairs
            auxPossiblePairs[minIndex][minIndex] = size
            for auxIndex in 0..<auxPossiblePairs.count {
                if auxIndex != index {
                    auxPossiblePairs[auxIndex][index] = 0
                }
            }
            
            var matches = computePairs(auxPossiblePairs, size: size-1)
            if matches.count == size-1 {
                matches[minIndex] = index
                return matches
            }
        }
        
        return [:]
    }
}
