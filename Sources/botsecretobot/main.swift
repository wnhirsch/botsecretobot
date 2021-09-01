//
//  main.swift
//  botsecretobot
//
//  Created by Wellington Nascente Hirsch on 01/09/21.
//

import Foundation
import TelegramBotSDK

// MARK: Main
var privateGetSessions: [Int64: Int64] = [:]
var privateGiveSessions: [Int64: Int64] = [:]
var sessions: [Int64: Session] = [:]

let token = readToken(from: "BOT_SECRETO_TOKEN")
let bot = TelegramBot(token: token)
let router = Router(bot: bot)

let tokenGet = readToken(from: "BOT_SECRETO_GET_TOKEN")
let botGet = TelegramBot(token: tokenGet)
let routerGet = Router(bot: botGet)

let tokenGive = readToken(from: "BOT_SECRETO_GIVE_TOKEN")
let botGive = TelegramBot(token: tokenGive)
let routerGive = Router(bot: botGive)

// MARK: - Main Router
router[Command.start.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync("command_error_private".localized, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    if sessions[chatId] == nil {
        context.respondAsync("start_message".localized, parseMode: .html)
    } else {
        context.respondAsync("restart_message".localized, parseMode: .html)
    }
    sessions[chatId] = Session()
    return true
}

router[Command.help.rawValue, .slashRequired] = { context in
    context.respondAsync("help_message".localized, parseMode: .html)
    return true
}

router[Command.commands.rawValue, .slashRequired] = { context in
    context.respondAsync("commands_message".localized, parseMode: .html)
    return true
}

router[Command.addme.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync("command_error_private".localized, parseMode: .html)
        return true
    }
    guard let user = context.message?.from, let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    if session.addUser(newUser: user) {
        context.respondAsync("add_user".localizedWithArgs(user.firstNameOrUsername), parseMode: .html)
    } else {
        context.respondAsync("added_user".localizedWithArgs(user.firstNameOrUsername), parseMode: .html)
    }
    return true
}

router[Command.removeme.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync("command_error_private".localized, parseMode: .html)
        return true
    }
    guard let user = context.message?.from, let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    if session.removeUser(user: user) {
        context.respondAsync("remove_user".localizedWithArgs(user.firstNameOrUsername), parseMode: .html)
    } else {
        context.respondAsync("removed_user".localizedWithArgs(user.firstNameOrUsername), parseMode: .html)
    }
    return true
}

router[Command.blockpair.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync("command_error_private".localized, parseMode: .html)
        return true
    }
    guard let userA = context.args.scanWord(), let userB = context.args.scanWord(), context.args.isAtEnd else {
        context.respondAsync("command_error".localized, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    if session.addBlock(userA: String(userA.dropFirst()), userB: String(userB.dropFirst())) {
        context.respondAsync("block_pair".localizedWithArgs(userA, userB), parseMode: .html)
    } else {
        context.respondAsync("blocked_pair".localizedWithArgs(userA, userB), parseMode: .html)
    }
    return true
}

router[Command.unblockpair.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync("command_error_private".localized, parseMode: .html)
        return true
    }
    guard let userA = context.args.scanWord(), let userB = context.args.scanWord(), context.args.isAtEnd else {
        context.respondAsync("command_error".localized, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    if session.removeBlock(userA: String(userA.dropFirst()), userB: String(userB.dropFirst())) {
        context.respondAsync("unblock_pair".localizedWithArgs(userA, userB), parseMode: .html)
    } else {
        context.respondAsync("unblocked_pair".localizedWithArgs(userA, userB), parseMode: .html)
    }
    return true
}

router[Command.list.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync("command_error_private".localized, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    context.respondAsync(session.listString, parseMode: .html)
    return true
}

router[Command.play.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync("command_error_private".localized, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    context.respondSync("play_loading".localized, parseMode: .html)
    if session.play() {
        context.respondAsync("play_success".localized, parseMode: .html)
    } else {
        context.respondAsync("play_error".localized, parseMode: .html)
    }
    return true
}

router.partialMatch = { _ in
    return true
}

router.unmatched = { context in
    context.respondAsync("command_error".localized, parseMode: .html)
    return true
}

// MARK: - Get Router
routerGet[Command.start.rawValue, .slashRequired] = { context in
    guard context.privateChat else {
        context.respondAsync("command_error_group".localized, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let user = context.message?.from else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    context.respondSync("start_private_loading".localized, parseMode: .html)
    if let sessionId = privateGetSessions[chatId], sessions[sessionId] != nil {
        context.respondAsync("start_private_get_message".localized, parseMode: .html)
    } else {
        if let session = sessions.first(where: { $0.value.userExists(userId: user.id) }) {
            privateGetSessions[chatId] = session.key
            sessions[session.key]?.addUserGetDM(userId: user.id, chatId: chatId)
            context.respondAsync("start_private_get_message".localized, parseMode: .html)
        } else {
            context.respondAsync("start_private_error".localized, parseMode: .html)
        }
    }
    return true
}

routerGet[Command.help.rawValue, .slashRequired] = { context in
    context.respondAsync("help_private_message".localized, parseMode: .html)
    return true
}

routerGet[.text] = { context in
    guard context.privateChat else {
        context.respondAsync("command_error_group".localized, parseMode: .html)
        return true
    }
    guard let user = context.message?.from,
          let chatId = context.chatId, let sessionId = privateGetSessions[chatId], let session = sessions[sessionId] else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    guard let message = context.message?.text else {
        context.respondAsync("command_error".localized, parseMode: .html)
        return true
    }
    if let userToGetChatId = session.getUserToGetDM(userId: user.id) {
        botGive.sendMessageSync(chatId: ChatId.chat(userToGetChatId),
                                text: "chat_from_give".localizedWithArgs(message),
                                parseMode: .html)
    } else {
        context.respondAsync("chat_error".localized, parseMode: .html)
    }
    return true
}

routerGet.unsupportedContentType = { context in
    context.respondAsync("chat_media_error".localized, parseMode: .html)
    return true
}

routerGet.partialMatch = { _ in
    return true
}

routerGet.unmatched = { context in
    context.respondAsync("command_error".localized, parseMode: .html)
    return true
}

// MARK: - Give Router
routerGive[Command.start.rawValue, .slashRequired] = { context in
    guard context.privateChat else {
        context.respondAsync("command_error_group".localized, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let user = context.message?.from else {
        context.respondAsync("runtime_error".localized, parseMode: .html)
        return true
    }
    context.respondSync("start_private_loading".localized, parseMode: .html)
    if let sessionId = privateGiveSessions[chatId] {
        if let session = sessions[sessionId], let userToGive = session.getUserToGive(userId: user.id) {
            context.respondAsync("start_private_give_message".localizedWithArgs(userToGive.firstName, userToGive.username ?? ""), parseMode: .html)
        } else {
            context.respondAsync("start_private_error".localized, parseMode: .html)
        }
    } else {
        if let session = sessions.first(where: { $0.value.userExists(userId: user.id) }),
           let userToGive = session.value.getUserToGive(userId: user.id) {
            privateGiveSessions[chatId] = session.key
            sessions[session.key]?.addUserGiveDM(userId: user.id, chatId: chatId)
            context.respondAsync("start_private_give_message".localizedWithArgs(userToGive.firstName, userToGive.username ?? ""), parseMode: .html)
        } else {
            context.respondAsync("start_private_error".localized, parseMode: .html)
        }
    }
    return true
}

routerGive[Command.help.rawValue, .slashRequired] = { context in
    context.respondAsync("help_private_message".localized, parseMode: .html)
    return true
}

routerGive[.text] = { context in
    guard context.privateChat else {
        context.respondAsync("command_error_group".localized, parseMode: .html)
        return true
    }
    guard let user = context.message?.from,
          let chatId = context.chatId, let sessionId = privateGiveSessions[chatId], let session = sessions[sessionId] else {
        context.respondAsync("chat_error".localized, parseMode: .html)
        return true
    }
    guard let message = context.message?.text else {
        context.respondAsync("command_error".localized, parseMode: .html)
        return true
    }
    if let userToGiveChatId = session.getUserToGiveDM(userId: user.id) {
        botGet.sendMessageSync(chatId: ChatId.chat(userToGiveChatId),
                               text: "chat_from_get".localizedWithArgs(message),
                               parseMode: .html)
    } else {
        context.respondAsync("chat_error".localized, parseMode: .html)
    }
    return true
}

routerGive.unsupportedContentType = { context in
    context.respondAsync("chat_media_error".localized, parseMode: .html)
    return true
}

routerGive.partialMatch = { _ in
    return true
}

routerGive.unmatched = { context in
    context.respondAsync("command_error".localized, parseMode: .html)
    return true
}

// MARK: - Execution
let queueGet = DispatchQueue(label: "br.com.botsecretogetbot")
queueGet.async {
    getBotExecute()
}

func getBotExecute() {
    while let update = botGet.nextUpdateSync() {
        do {
            try routerGet.process(update: update)
        } catch {
            fatalError("Get Server stopped due to error: \(String(describing: botGet.lastError))")
        }
    }
    fatalError("Get Server stopped due to error: \(String(describing: botGet.lastError))")
}

let queueGive = DispatchQueue(label: "br.com.botsecretogivebot")
queueGive.async {
    giveBotExecute()
}

func giveBotExecute() {
    while let update = botGive.nextUpdateSync() {
        do {
            try routerGive.process(update: update)
        } catch {
            fatalError("Give Server stopped due to error: \(String(describing: botGive.lastError))")
        }
    }
    fatalError("Give Server stopped due to error: \(String(describing: botGive.lastError))")
}

while let update = bot.nextUpdateSync() {
    try router.process(update: update)
}

fatalError("Main Server stopped due to error: \(String(describing: bot.lastError))")
