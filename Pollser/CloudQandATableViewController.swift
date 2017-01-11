//
//  CloudQandATableViewController.swift
//  Pollser
//
//  Created by Braden Gray on 1/5/17.
//  Copyright © 2017 Graycode. All rights reserved.
//

import UIKit
import CloudKit

class CloudQandATableViewController: QandATableViewController {
    
    var ckQandARecord: CKRecord {
        get {
            if _ckQandARecord == nil {
                _ckQandARecord = CKRecord(recordType: Cloud.Entity.QandA)
            }
            return _ckQandARecord!
        }
        set {
            _ckQandARecord = newValue
        }
    }
    
    private var _ckQandARecord: CKRecord? {
        didSet {
            let question = ckQandARecord[Cloud.Attribute.Question] as? String ?? ""
            let answers = ckQandARecord[Cloud.Attribute.Answers] as? [String] ?? []
            qanda = QandA(question: question, answers: answers)
            
            asking = ckQandARecord.wasCreatedByThisUser
        }
    }
    
    private let database = CKContainer.default().publicCloudDatabase
    
    @objc private func iCloudUpdate() {
        if !qanda.question.isEmpty && !qanda.answers.isEmpty {
            ckQandARecord[Cloud.Attribute.Question] = qanda.question as CKRecordValue?
            ckQandARecord[Cloud.Attribute.Answers] = qanda.answers as CKRecordValue?
            iCloudSaveRecord(record: ckQandARecord)
        }
    }
    
    private func iCloudSaveRecord(record: CKRecord) {
        database.save(record) { (savedRecord, error) in
            if error?._code == CKError.serverRecordChanged.rawValue {
                //ignore
            } else if error != nil {
                self.retryAfter(error: error as NSError?, withSelector: #selector(self.iCloudUpdate))
            }
        }
    }
    
    private func retryAfter(error: NSError?, withSelector selector: Selector) {
        if let retryInterval = error?.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
            DispatchQueue.main.async {
                Timer.scheduledTimer(
                    timeInterval: retryInterval,
                    target: self,
                    selector: selector,
                    userInfo: nil,
                    repeats: false
                )
            }
        }
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)
        iCloudUpdate()
    }
}
