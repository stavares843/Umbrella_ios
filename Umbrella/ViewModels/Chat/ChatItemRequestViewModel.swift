//
//  ChatItemRequestViewModel.swift
//  Umbrella
//
//  Created by Lucas Correa on 01/07/2019.
//  Copyright © 2019 Security First. All rights reserved.
//

import UIKit

class ChatItemRequestViewModel {
    
    //
    // MARK: - Properties
    var item: (name: String, type: ChatRequestType, icon: UIImage)!
    var sqlManager: SQLManager
    var umbrella: Umbrella = UmbrellaDatabase.umbrellaStatic
    var checklists: [CheckList] = [CheckList]()
    var service: MediaService
    var userLogged: UserMatrix!
    
    lazy var formAnswerDao: FormAnswerDao = {
        let formAnswerDao = FormAnswerDao(sqlProtocol: self.sqlManager)
        return formAnswerDao
    }()
    
    init() {
        self.sqlManager = SQLManager(databaseName: Database.name, password: Database.password)
        self.service = MediaService(client: UmbrellaClient())
    }
    
    /// Load the formAnswers
    ///
    /// - Parameters:
    ///   - formAnswerId: Int
    ///   - formId: Int
    /// - Returns: Array of FormAnswer
    func loadFormAnswersTo(formAnswerId: Int, formId: Int) -> [FormAnswer] {
        return formAnswerDao.listFormAnswers(at: Int64(formAnswerId), formId: Int64(formId))
    }
    
    func uploadFile(filename: String, fileURL: URL, success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        
        service.uploadFile(accessToken: self.userLogged.accessToken, filename: filename, fileURL: fileURL, success: { (response) in
            success(response as AnyObject)
        }, failure: { (response, object, error) in
            failure(response, object, error)
        })
    }
}