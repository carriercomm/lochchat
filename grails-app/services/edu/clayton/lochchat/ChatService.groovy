package edu.clayton.lochchat
import grails.transaction.Transactional
import org.codehaus.groovy.grails.web.servlet.mvc.GrailsParameterMap
import org.codehaus.groovy.grails.web.util.WebUtils
import org.springframework.http.HttpStatus
import org.springframework.mail.MailSendException

@Transactional
class ChatService {

  def mailService
  def messageService
  def springSecurityService

  Map createChat(GrailsParameterMap params) {
    Log logInstance = new Log(messages: [])
    logInstance.save(flush: true)

    Chat chat = new Chat(uniqueId: params.url?.split("/")?.last(), startTime: new Date(), log: logInstance, users: [])
    if (!chat.save(flush: true)) {
      logInstance.delete(flush: true)
      return [status: HttpStatus.BAD_REQUEST, message: messageService.getErrorMessage(chat)]
    }

    if (params.emails) {
      params.emails.trim()?.split(",")?.each { email ->
        emailUser(email, chat)
      }
    }
    return [status: HttpStatus.OK, data: [chat: chat, url: chat.url]]
  }

  Map invite(GrailsParameterMap params) {
    Chat chat = Chat.findByUniqueId(params.uniqueId)
    if (params.emails) {
      params.emails.split(",").each { String email ->
        emailUser(email, chat)
      }
    }
    return [status: HttpStatus.OK]
  }

  Map deleteChat(String uniqueId) {
    Chat chat = Chat.findByUniqueId(uniqueId)
    User user = springSecurityService.currentUser

    if (user.chats.contains(chat) && (chat.users - user).size() == 0) {
      user.chats.remove(chat)
      chat.delete(flush: true)
      return [status: HttpStatus.OK, data: null]
    }
    return [status: HttpStatus.NOT_FOUND]
  }

  Map enterRoom(String uniqueId) {
    def chatroom = Chat.findByUniqueId(uniqueId)
    if (!chatroom) {
      return [status: HttpStatus.NOT_FOUND]
    }

    if (springSecurityService.isLoggedIn()) {
      User user = springSecurityService.currentUser
      if (!chatroom.users.contains(user)) {
        user.chats.add(chatroom)
        user.save(flush: true)
      }
    } else {
      def session = WebUtils.retrieveGrailsWebRequest().session
      session.chatId = chatroom.uniqueId
    }
    return [status: HttpStatus.OK, chatroom: chatroom]
  }


  protected void emailUser(String email, Chat chat) {
    log.info("Emailing $email...")
    try {
      mailService.sendMail {
        to email
        from 'LochChat'
        subject "LochChat Invite"
        body "You've been invited to join a chat at the following url: ${chat.url}"
      }
    } catch (MailSendException e) {
      log.error("Could not deliver email to recipient.", e)
      new Message(contents: "Could not deliver email to recipient: $email. Are you sure this email address exists?", log: chat.log).save(flush: true)
      chat.log.save(flush: true)
      chat.save(flush: true)
    }
  }
}