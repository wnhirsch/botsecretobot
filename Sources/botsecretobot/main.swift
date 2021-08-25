import Foundation
import TelegramBotSDK

// MARK: - Structures
enum Command: String, CaseIterable {
    case start
    case help
    case commands
    case addme
    case removeme
    case blockpair
    case unblockpair
    case list
    case play
    case chatget
    case chatgive
}

extension User {
    var firstNameOrUsername: String {
        if let username = self.username {
            return "@\(username)"
        } else {
            return firstName
        }
    }
}

class Session {
    private var users: [User] = []
    private var blockedMatches: [(User, User)] = []
    private var userMatches: [(User, User)] = []
    private var userDMs: [Int64: Int64] = [:]
    private var wasPlayedFunction: Bool = false
    
    var wasPlayed: Bool {
        return wasPlayedFunction && userMatches.count == users.count
    }
    
    var listString: String {
        var desc = "\(USERS_PARTICIPATING)\n"
        
        if users.isEmpty {
            desc.append("\(NO_USERS)\n")
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
        
        desc.append("\n\(USERS_NOT_MATCH)\n")
        if blockedMatches.isEmpty {
            desc.append("\(NO_USERS)\n")
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
        return self.userDMs[userToGet.id]
    }
    
    func getUserToGiveDM(userId: Int64) -> Int64? {
        guard let userToGive = getUserToGive(userId: userId) else { return nil }
        return self.userDMs[userToGive.id]
    }
    
    func addUserDM(userId: Int64, chatId: Int64) {
        self.userDMs[userId] = chatId
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


// MARK: - Localizable
let START_MESSAGE = "<b>Olá pessoal! 👋</b> Vim aqui para ajudar vocês nesse Amigo Secreto 🎁. Basta chamar todos os amigos que possam estar faltando, fazer as configurações com os comandos /addme, /removeme, /blockpair, /unblockpair e /list e começar o sorteio com o /play.\n\nCaso precise de ajuda com os comandos, basta usar o /help."
let RESTART_MESSAGE = "Sorteio reiniciado, todas configurações foram removidas! ✅"
let START_PRIVATE_LOADING = "⌛ Aguarde um momento enquanto eu verifico a situação do seu sorteio..."
let START_PRIVATE_MESSAGE = "Perfeito, te encontrei!\nVocê está participando de um Amigo Secreto ativo e o participante que te foi sorteado é...\n%@ @%@\n\n<b>⚠️NÃO DIVULGUE ESSA INFORMAÇÃO!⚠️</b>\nSomente use este chat para entrar em contato com quem você deve presentear e com quem te presenteou. Para isso, use os comandos /chatget e /chatgive seguido da mensagem que deseja enviar."
let START_PRIVATE_ERROR = "❌ Não encontrei nenhum sorteio ativo associado ao seu usuário. Verifique se você participou de um sorteio em um grupo e tente novamente."
let RUNTIME_ERROR = "⚠️ Houve algum problema ao executar o comando. Verifique as minhas permissões, o histórico de comandos e tente novamente."
let COMMAND_ERROR = "⚠️ Comando Inválido! Verifique se ele foi chamado corretamente com todos os argumentos exigidos."
let HELP_MESSAGE = "O <b>Bot Secreto</b> é um BOT 🤖 que ajuda grupos de amigos a realizarem um Amigo Secreto 🎁 de qualquer tipo que seja. Para tudo funcionar, você precisa me adicionar em um grupo com os seus amigos e garantir que todos eles estejam lá antes de começar o jogo. Para gerenciar esse sorteio, existem uma série de comandos para te ajudar. A seguir você encontrará uma descrição mais detalhada de cada comando:\n\n/start - Inicia o BOT limpando todas as configurações realizadas.\n/help - Apresenta lista de comandos e detalhes sobre a sua execução, aka esta que você está vendo.\n/commands - Apresenta lista de comandos com descrição resumida.\n/addme - Você começará a fazer parte do sorteio. Caso já faça, nada acontecerá.\n/removeme - Você deixará de fazer parte do sorteio. Caso já faça, nada acontecerá.\n/blockpair - Execute esse comando marcando 2 participantes do sorteio e eles ficarão impedidos de sortear um ao outro.\n/unblockpair - Desfaz restrição entre 2 usuários. Caso não exista, nada acontecerá.\n/list - Lista todas as configurações atuais sobre o jogo, mostrando os usuários que irão participar, os que não irão e os que não irão tirar um ou outro.\n/play - Inicia o sorteio e informa para cada participante no privado quem ele deve presentear. Qualquer alteração sobre as configurações do sorteio não podem mais ser realizadas, apenas usando o comando /start.\n/chatget - Envia uma mensagem anônima e privada para a pessoa que vai te presentear, basta executar esse comando seguido da mensagem que desejar.\n/chatgive - Envia uma mensagem anônima e privada para a pessoa que você deve presentear, basta executar esse comando seguido da mensagem que desejar.\n\nResumindo: comece com /start, use o /addme, /removeme, /blockpair e /unblockpair para configurar as restrições do sorteio, use o /list para verificar o estado atual das restrições, comece com o /play, converse com os seus amigos secretos usando o /chatget e o /chatgive e termine o jogo informando a todos quem tirou quem.\n\nE o mais importante, <b>divirtam-se! 🥳🎁🎉</b>"
let COMMANDS_MESSAGE = "/start - Inicia o BOT limpando todas as configurações.\n/help - Apresenta lista de comandos e detalhes sobre a sua execução.\n/commands - Apresenta lista de comandos.\n/addme - Você começará a fazer parte do sorteio.\n/removeme - Você deixará de fazer parte do sorteio.\n/blockpair - Impede que 2 usuários sorteiem um ao outro.\n/unblockpair - Desfaz restrição entre 2 usuários.\n/list - Lista todas as configurações atuais sobre o jogo.\n/play - Inicia o sorteio.\n/chatget - Envia uma mensagem anônima e privada para a pessoa que vai te presentear.\n/chatgive - Envia uma mensagem anônima e privada para a pessoa que você deve presentear."
let COMMAND_ERROR_PRIVATE = "⚠️ Este comando só pode ser utilizado em um grupo!"
let COMMAND_ERROR_GROUP = "⚠️ Este comando só pode ser utilizado em uma mensagem privada!"
let ADD_USER = "✅ O usuário %@ foi adicionado ao sorteio."
let ADDED_USER = "⚠️ O usuário %@ já fazia parte do sorteio."
let REMOVE_USER = "❌ O usuário %@ foi removido do sorteio."
let REMOVED_USER = "⚠️ O usuário %@ não fazia parte do sorteio."
let BLOCK_PAIR = "❌ Os usuários %@ e %@ não poderão sortear um ao outro."
let BLOCKED_PAIR = "⚠️ Os usuários %@ e %@ já não podiam sortear um ao outro."
let UNBLOCK_PAIR = "✅ Os usuários %@ e %@ poderão sortear um ao outro."
let UNBLOCKED_PAIR = "⚠️ Os usuários %@ e %@ já podiam sortear um ao outro."
let USERS_PARTICIPATING = "<b>Participantes do sorteio:</b>"
let USERS_NOT_MATCH = "<b>Pares impossíveis:</b>"
let NO_USERS = "<i>Nenhum usuário</i>"
let PLAY_LOADING = "⌛ Aguarde um momento enquanto eu realizo o sorteio..."
let PLAY_SUCCESS = "<b>✅ Sorteio realizado com sucesso!</b>\nAgora cada um dos participantes deve me chamar no privado @botsecretobot para começar a falar uns com os outros anonimamente sobre detalhes dos presentes. Basta entrar no chat e me chamar com /start."
let PLAY_ERROR = "❌ Houve algum erro ao realizar o sorteio! Verifique as restrições e os usuários que estão participando e tente novamente."
let CHAT_FROM_GET = "<b>Participante que te presenteará disse:</b>\n<i>responda com /chatget</i>\n\n%@"
let CHAT_FROM_GIVE = "<b>Participante que você deve presentear disse:</b>\n<i>responda com /chatgive</i>\n\n%@"
let CHAT_ERROR = "⚠️ Houve algum problema ao enviar essa mensagem! Provavelmente o usuário ainda não se conectou comigo ou existe algum bloqueio que me impede de lhe enviar mensagens."


// MARK: Main
var privateSessions: [Int64: Int64] = [:]
var sessions: [Int64: Session] = [:]
let token = readToken(from: "BOT_SECRETO_TOKEN")
let bot = TelegramBot(token: token)
let router = Router(bot: bot)

router[Command.start.rawValue, .slashRequired] = { context in
    guard let chatId = context.chatId, let user = context.message?.from else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    if context.privateChat {
        context.respondSync(START_PRIVATE_LOADING, parseMode: .html)
        if let sessionId = privateSessions[chatId] {
            if let session = sessions[sessionId], let userToGive = session.getUserToGive(userId: user.id) {
                context.respondAsync(String(format: START_PRIVATE_MESSAGE, userToGive.firstName, userToGive.username ?? ""), parseMode: .html)
            } else {
                context.respondAsync(START_PRIVATE_ERROR, parseMode: .html)
            }
        } else {
            if let session = sessions.first(where: { $0.value.userExists(userId: user.id) }),
               let userToGive = session.value.getUserToGive(userId: user.id) {
                privateSessions[chatId] = session.key
                sessions[session.key]?.addUserDM(userId: user.id, chatId: chatId)
                context.respondAsync(String(format: START_PRIVATE_MESSAGE, userToGive.firstName, userToGive.username ?? ""), parseMode: .html)
            } else {
                context.respondAsync(START_PRIVATE_ERROR, parseMode: .html)
            }
        }
    } else {
        if sessions[chatId] == nil {
            context.respondAsync(START_MESSAGE, parseMode: .html)
        } else {
            context.respondAsync(RESTART_MESSAGE, parseMode: .html)
        }
        sessions[chatId] = Session()
    }
    return true
}

router[Command.help.rawValue, .slashRequired] = { context in
    context.respondAsync(HELP_MESSAGE, parseMode: .html)
    return true
}

router[Command.commands.rawValue, .slashRequired] = { context in
    context.respondAsync(COMMANDS_MESSAGE, parseMode: .html)
    return true
}

router[Command.addme.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync(COMMAND_ERROR_PRIVATE, parseMode: .html)
        return true
    }
    guard let user = context.message?.from, let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    if session.addUser(newUser: user) {
        context.respondAsync(String(format: ADD_USER, user.firstNameOrUsername), parseMode: .html)
    } else {
        context.respondAsync(String(format: ADDED_USER, user.firstNameOrUsername), parseMode: .html)
    }
    return true
}

router[Command.removeme.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync(COMMAND_ERROR_PRIVATE, parseMode: .html)
        return true
    }
    guard let user = context.message?.from, let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    if session.removeUser(user: user) {
        context.respondAsync(String(format: REMOVE_USER, user.firstNameOrUsername), parseMode: .html)
    } else {
        context.respondAsync(String(format: REMOVED_USER, user.firstNameOrUsername), parseMode: .html)
    }
    return true
}

router[Command.blockpair.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync(COMMAND_ERROR_PRIVATE, parseMode: .html)
        return true
    }
    guard let userA = context.args.scanWord(), let userB = context.args.scanWord(), context.args.isAtEnd else {
        context.respondAsync(COMMAND_ERROR, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    if session.addBlock(userA: String(userA.dropFirst()), userB: String(userB.dropFirst())) {
        context.respondAsync(String(format: BLOCK_PAIR, userA, userB), parseMode: .html)
    } else {
        context.respondAsync(String(format: BLOCKED_PAIR, userA, userB), parseMode: .html)
    }
    return true
}

router[Command.unblockpair.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync(COMMAND_ERROR_PRIVATE, parseMode: .html)
        return true
    }
    guard let userA = context.args.scanWord(), let userB = context.args.scanWord(), context.args.isAtEnd else {
        context.respondAsync(COMMAND_ERROR, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    if session.removeBlock(userA: String(userA.dropFirst()), userB: String(userB.dropFirst())) {
        context.respondAsync(String(format: UNBLOCK_PAIR, userA, userB), parseMode: .html)
    } else {
        context.respondAsync(String(format: UNBLOCKED_PAIR, userA, userB), parseMode: .html)
    }
    return true
}

router[Command.list.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync(COMMAND_ERROR_PRIVATE, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    context.respondAsync(session.listString, parseMode: .html)
    return true
}

router[Command.play.rawValue, .slashRequired] = { context in
    guard !context.privateChat else {
        context.respondAsync(COMMAND_ERROR_PRIVATE, parseMode: .html)
        return true
    }
    guard let chatId = context.chatId, let session = sessions[chatId] else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    context.respondSync(PLAY_LOADING, parseMode: .html)
    if session.play() {
        context.respondAsync(PLAY_SUCCESS, parseMode: .html)
    } else {
        context.respondAsync(PLAY_ERROR, parseMode: .html)
    }
    return true
}

router[Command.chatget.rawValue, .slashRequired] = { context in
    guard context.privateChat else {
        context.respondAsync(COMMAND_ERROR_GROUP, parseMode: .html)
        return true
    }
    guard let user = context.message?.from,
          let chatId = context.chatId, let sessionId = privateSessions[chatId], let session = sessions[sessionId] else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    let message = context.args.scanRestOfString()
    guard !message.isEmpty else {
        context.respondAsync(COMMAND_ERROR, parseMode: .html)
        return true
    }
    if let userToGetChatId = session.getUserToGetDM(userId: user.id) {
        bot.sendMessageSync(chatId: ChatId.chat(userToGetChatId),
                            text: String(format: CHAT_FROM_GIVE, message),
                            parseMode: .html)
    } else {
        context.respondAsync(CHAT_ERROR, parseMode: .html)
    }
    return true
}

router[Command.chatgive.rawValue, .slashRequired] = { context in
    guard context.privateChat else {
        context.respondAsync(COMMAND_ERROR_GROUP, parseMode: .html)
        return true
    }
    guard let user = context.message?.from,
          let chatId = context.chatId, let sessionId = privateSessions[chatId], let session = sessions[sessionId] else {
        context.respondAsync(RUNTIME_ERROR, parseMode: .html)
        return true
    }
    let message = context.args.scanRestOfString()
    guard !message.isEmpty else {
        context.respondAsync(COMMAND_ERROR, parseMode: .html)
        return true
    }
    if let userToGiveChatId = session.getUserToGiveDM(userId: user.id) {
        bot.sendMessageSync(chatId: ChatId.chat(userToGiveChatId),
                            text: String(format: CHAT_FROM_GET, message),
                            parseMode: .html)
    } else {
        context.respondAsync(CHAT_ERROR, parseMode: .html)
    }
    return true
}

router.partialMatch = { _ in
    return true
}

router.unmatched = { context in
    context.respondAsync(COMMAND_ERROR, parseMode: .html)
    return true
}

while let update = bot.nextUpdateSync() {
    try router.process(update: update)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
