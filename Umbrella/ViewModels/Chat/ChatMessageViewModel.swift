//
//  ChatMessageViewModel.swift
//  ChatBubble
//
//  Created by Lucas Correa on 25/06/2019.
//  Copyright © 2019 Lucas Correa. All rights reserved.
//

import Foundation

class ChatMessageViewModel {
    
    //
    // MARK: - Properties
    var service: UmbrellaMatrixRoomService
    var mediaService: MediaService
    
    var messages: [[Message]]!
    var userLogged: UserMatrix!
    var room: Room!
    var sqlManager: SQLManager
    
    lazy var messageDao: MessageDao = {
        let messageDao = MessageDao(sqlProtocol: self.sqlManager)
        return messageDao
    }()
    
    //
    // MARK: - Init
    init() {
        self.messages = [[Message]]()
        self.service = UmbrellaMatrixRoomService(client: UmbrellaClient())
        self.mediaService = MediaService(client: UmbrellaClient())
        self.sqlManager = SQLManager(databaseName: Database.name, password: Database.password)
    }
    
    //
    // MARK: - Public Functions
    
    func sendMessage(messageType: RoomTypeMessage, message: String, url: String, success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        
        service.sendMessage(accessToken: self.userLogged.accessToken, roomId: self.room.roomId!, type: messageType, message: message, url: url, success: { _ in
            success("")
        }, failure: { (response, object, error) in
            failure(response, object, error)
        })
    }
    
    func getMessages(success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        
        let status = Reachability().connectionStatus()
        if status.description == "Offline" {
            self.messages.removeAll()
            let msgs = self.messageDao.listRoomId(roomId: self.room.roomId!)
            msgs.forEach({ (chatMessage) in
                chatMessage.isUserLogged = (chatMessage.userId == self.userLogged.userId)
            })
            
            self.groupMessagesByDate(messages: msgs)
            success(nil)
        } else {
            
            let pagination = UserDefaults.standard.object(forKey: self.room.roomId!)
            var dir = "b"
            var from = ""
            
            if pagination != nil {
                let paginationString = (pagination as? String)!
                let pagArray = paginationString.components(separatedBy: ";")
                
                if Int(pagArray[2])! == 1 {
                    dir = "f"
                    // start
                    from = pagArray[0]
                } else if Int(pagArray[2])! > 1 {
                    dir = "f"
                    // end
                    from = pagArray[1]
                }
            }
            
            service.getMessages(accessToken: self.userLogged.accessToken, roomId: self.room.roomId!, dir: dir, from: from, success: { (object) in
                let chatMessage = (object as? ChatMessage)!
                let chatMessageFilter = chatMessage.messages.filter { $0.type == "m.room.message" }
                
                chatMessageFilter.forEach({ (chatMessage) in
                    chatMessage.isUserLogged = (chatMessage.userId == self.userLogged.userId)
                })
                
                if pagination == nil {
                    self.groupMessagesByDate(messages: chatMessageFilter)
                    self.insertMessageDB()
                    self.removeMessageDuplcate()
                } else {
                    
                    var array = [Message]()
                    for messages in self.messages {
                        for message in messages {
                            array.append((message.copy() as? Message)!)
                        }
                    }
                    
                    let finalArray: [Message] = array + chatMessageFilter
                    self.messages.removeAll()
                    self.groupMessagesByDate(messages: finalArray)
                    self.insertMessageDB()
                    self.removeMessageDuplcate()
                }
                
                success(chatMessage as AnyObject)
            }, failure: { (response, object, error) in
                failure(response, object, error)
            })
        }
    }
    
    func downloadFile(filename: String, uri: String, success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        
        mediaService.downloadFile(filename: filename, uri: uri, success: { (response) in
            success(response)
        }, failure: { (response, object, error) in
            failure(response, object, error)
        })
    }
    
    func joinRoom(success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        service.joinRoom(accessToken: self.userLogged.accessToken, roomId: self.room.roomId!, success: { _ in
            success("")
        }, failure: { (response, object, error) in
            failure(response, object, error)
        })
    }
    
    //
    // MARK: - Private Functions
    fileprivate func groupMessagesByDate(messages: [Message]) {
        let groupedMessages = Dictionary(grouping: messages) { (element) -> Date in
            return element.millisecondsToDate().reduceToMonthDayYear()
        }
        
        // provide a sorting for your keys somehow
        let sortedKeys = groupedMessages.keys.sorted()
        sortedKeys.forEach { (key) in
            var values = groupedMessages[key]
            values!.sort(by: { $0.originTime < $1.originTime })
            self.messages.append(values ?? [])
        }
    }
    
    fileprivate func insertMessageDB() {
        for messageGroup in self.messages {
            for message in messageGroup {
                _ = self.messageDao.insert(message)
            }
        }
    }
    
    fileprivate func removeMessageDuplcate() {
        var messagesFinal = [[Message]]()
        for messageGroup in self.messages {
            var gg = messageGroup.clone()
            for message in gg {
                let filter = messageGroup.filter {$0.eventId == message.eventId }
                if filter.count >= 2 {
                    let msg = filter.first!
                    gg.removeObject(obj: msg)
                    gg.append(msg)
                    print(gg)
                }
            }
            messagesFinal.append(gg)
        }
        self.messages = messagesFinal
    }
}
