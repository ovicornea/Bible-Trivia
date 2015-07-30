//
//  ViewController.swift
//  Bible Quiz - Do you know your Bible?
//
//  Created by Ovi Cornea on 25/07/15.
//  Copyright (c) 2015 Hope for the Future. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import Dispatch
import CoreData

class ViewController: UIViewController {
    
    let reachability = Reachability.reachabilityForInternetConnection()
    
    var internetConnection = true
    
    var question =  String()
    var answers: [String]!
    var answer: String!
    var score: Int = 0
    var audioPlayer = AVAudioPlayer()
    
    var objectsIDsArray = [String]()
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    
    
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var feedbackLabel: UILabel!
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var resetScore: UIButton!
    @IBAction func resetScore(sender: AnyObject) {
        
        resetAlert()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        hideAll()
        
        reachability.whenReachable = { reachability in
            if reachability.isReachableViaWiFi() {
                
                self.resetAnswerButtons()
                
                self.internetConnection = true
                self.callQuestions()
                
                //internet is reachable via wifi or cellular
                
            }
        }
        reachability.whenUnreachable = { reachability in
            
            self.internetConnection = false
            self.hideAll()
            //internet is not reachable
            
        }
        
        reachability.startNotifier()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        storeLevel1FromParseToCore()
        
        loadScore()
        adjustInterface()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "test:", name:"loadquestions", object: nil)

        
        reachability.whenReachable = { reachability in
            if reachability.isReachableViaWiFi() {
                
                self.resetAnswerButtons()
                self.internetConnection = true
                self.callQuestions()
                //internet is reachable via wifi or cellular
                
            }
        }
        reachability.whenUnreachable = { reachability in
            
            self.internetConnection = false
            //internet is not reachable
            
        }
        
        reachability.startNotifier()
        
        // Initial reachability check
        if reachability.isReachable() {
            

            internetIsReachable()
            
            
        } else {
            
            internetIsNotReachable()
        }

      
    }
    
    func storeLevel1FromParseToCore() {
        
        let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let context:NSManagedObjectContext = appDel.managedObjectContext!
        
        var entity = NSEntityDescription.entityForName("Level1", inManagedObjectContext: context)
        
       
        
        let insertNew = NSEntityDescription.insertNewObjectForEntityForName("Level1", inManagedObjectContext: context) as! NSManagedObject
        
        let query = PFQuery(className: "Level_1")
        query.selectKeys(["Question","Answer", "Answers"])
        
        query.findObjectsInBackgroundWithBlock({(level1Objects: [AnyObject]?, error: NSError?)-> Void in
            
            if error == nil {
                
                for obj: AnyObject in level1Objects! {
                    
                    //println(level1Objects!.count)
                    
                    insertNew.setValue(obj.objectForKey("Question"), forKey: "question")
                    insertNew.setValue(obj.objectForKey("Answer"), forKey: "answer")
                    //insertNew.setValue(obj.objectForKey("Answers"), forKey: "answers1")
                    
                    context.save(nil)
                    
                    let correctAnswer = obj.objectForKey("Answer") as! String
                    let question = obj.objectForKey("Question") as! String
                    //let wrongAnswer = obj.objectForKey("Answers") as! String
                    
                    println(correctAnswer)
                    //println(question)
                    //println(wrongAnswer)
                    
                }
            }
        })
    }
  
    func test(notification: NSNotification) {
        
        //println("Notification!")
        self.resetAnswerButtons()
        
    }
    
    deinit {
        
        reachability.stopNotifier()
        
        if internetConnection {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: ReachabilityChangedNotification, object: nil)
        }
    }
    
    func internetIsReachable() {
        
        internetConnection = true
        //println("Internet is Reachable")
        callQuestions()
        feedbackLabel.hidden = true
    }
    
    func internetIsNotReachable() {
        
        internetConnection = false
        self.questionLabel.text = "There is an error with the network and I can't load. Sorry for that!"
        self.questionLabel.textColor = UIColor.redColor()
        self.hideAll()
    }
    
    func resetAlert() {
        
        let alert = UIAlertController(title: "Are you sure you want to reset?", message: "Continuing will reset your score.", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .Default) { (UIAlertAction) -> Void in
            
            self.resetAnswerButtons()
            self.score = 0
            self.scoreLabel.text = "score: 0"
            self.saveScore()
            
        }
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func callQuestions() {
    
        
        var countQuery = PFQuery(className: "QA")
        countQuery.countObjectsInBackgroundWithBlock { (count: Int32, error: NSError?) -> Void in
            
            if (error == nil) {

                let randomNumber = Int(arc4random_uniform(UInt32(count)))
                
                //println("\(count) questions")
                
                
                var query = PFQuery(className: "QA")
                query.skip = randomNumber
                query.limit = 1
                query.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
                    
                    if (error == nil) {
                        
                        var object: AnyObject = objects![0]
                        self.question = object ["Question"] as! String!
                        self.answers = object ["Answers"] as! Array!
                        self.answer = object ["Answer"] as! String!
                        
                        
                        
                        if (self.answers.count > 0) {
                            
                            self.questionLabel.text = self.question
                            
                            self.button1.setTitle(self.answers[0], forState: .Normal)
                            self.button2.setTitle(self.answers[1], forState: UIControlState.Normal)
                            self.button3.setTitle(self.answers[2], forState: UIControlState.Normal)
                            self.button4.setTitle(self.answers[3], forState: UIControlState.Normal)
                            
                            NSNotificationCenter.defaultCenter().postNotificationName("loadquestions", object: nil)
        
                            self.resetAnswerButtons()
                            
                        } else {
                            
                            self.questionLabel.text = "There is an error with the server and I can't load. Sorry for that!"
                            self.questionLabel.textColor = UIColor.redColor()
                            self.hideAll()
                        }
                        
                    } else {
                        
                        self.questionLabel.text = "There is an error with the network and I can't load. Sorry for that!"
                        self.questionLabel.textColor = UIColor.redColor()
                        self.hideAll()
                        
                    }
                }
            } else {
                
                self.questionLabel.text = "There is an error with the network and I can't load. Sorry for that!"
                self.questionLabel.textColor = UIColor.redColor()
                self.hideAll()
            }
        }
        
        resetAnswerButtons()
    }
    
    func loadScore() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        score = defaults.integerForKey("score")
        scoreLabel.text = "score: \(score)"
        
    }
    
    func saveScore() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(score, forKey: "score")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //delays code
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func correctAnswerResults() {
        
        feedbackLabel.hidden = false
        feedbackLabel.text = "Correct! +1"
        feedbackLabel.textColor = UIColor.greenColor()
        score++
        scoreLabel.text = "score: \(score)"
        saveScore()
        
        
        
        playSoundCorrect()
        
        button1.enabled = false
        button2.enabled = false
        button3.enabled = false
        button4.enabled = false

        
        
        delay(1.0) {
            
            self.playSoundButton()
            self.callQuestions()
        }
 
    }
    
    func wrongAnswerResults() {
        
        feedbackLabel.hidden = false
        feedbackLabel.text = "Wrong Answer"
        feedbackLabel.textColor = UIColor.redColor()
        
        playSoundWrong()
        
        button1.enabled = false
        button2.enabled = false
        button3.enabled = false
        button4.enabled = false
        
        delay(1.0) {
            
            self.playSoundButton()
            
            
            
            self.callQuestions()
        }
        
    }
    
    func playSoundCorrect() {
        
        var alertSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("correct", ofType: "mp3")!)
        
        var error: NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: alertSound, error: &error)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
    }
    
    func playSoundWrong() {
        
        var alertSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("wrong", ofType: "wav")!)
        
        var error: NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: alertSound, error: &error)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
    }
    
    func playSoundButton() {
        
        var alertSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("button", ofType: "wav")!)
        
        var error: NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: alertSound, error: &error)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    }
    
    func resetAnswerButtons() {
        
        button1.alpha = 1.0
        button2.alpha = 1.0
        button3.alpha = 1.0
        button4.alpha = 1.0
        button1.enabled = true
        button2.enabled = true
        button3.enabled = true
        button4.enabled = true
        resetScore.hidden = false
        
    }
    
    func hideAll() {
        
        button1.alpha = 0.3
        button2.alpha = 0.3
        button3.alpha = 0.3
        button4.alpha = 0.3
        button1.enabled = false
        button2.enabled = false
        button3.enabled = false
        button4.enabled = false
        resetScore.hidden = true
        
    }
    
    @IBAction func button1Action(sender: AnyObject) {
        
        
        button2.alpha = 0.3
        button3.alpha = 0.3
        button4.alpha = 0.3
        
        button1.enabled = false
        button2.enabled = false
        button3.enabled = false
        button4.enabled = false
        
        
        if (answer == "0") {
            
            correctAnswerResults()
            
        } else {
            
            wrongAnswerResults()
        }
    }
    
    @IBAction func button2Action(sender: AnyObject) {
        
        button1.alpha = 0.3
        button3.alpha = 0.3
        button4.alpha = 0.3
        
        button1.enabled = false
        button2.enabled = false
        button3.enabled = false
        button4.enabled = false
        
        if (answer == "1") {
            
            correctAnswerResults()
            
        } else {
            
            wrongAnswerResults()
        }
        
    }

    @IBAction func button3Action(sender: AnyObject) {
        
        button1.alpha = 0.3
        button2.alpha = 0.3
        button4.alpha = 0.3
        
        button1.enabled = false
        button2.enabled = false
        button3.enabled = false
        button4.enabled = false
        
        if (answer == "2") {
            
           correctAnswerResults()
            
        } else {
            
           wrongAnswerResults()
        }
        
    }

    @IBAction func button4Action(sender: AnyObject) {
        
        button1.alpha = 0.3
        button2.alpha = 0.3
        button3.alpha = 0.3
        
        button1.enabled = false
        button2.enabled = false
        button3.enabled = false
        button4.enabled = false
        
        if (answer == "3") {
            
            correctAnswerResults()
            
        } else {
            
           wrongAnswerResults()
        }
        
    }
    
    func adjustInterface() {
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        button1.center = CGPointMake(screenWidth / 2, button1.center.y)
        button2.center = CGPointMake(screenWidth / 2, button2.center.y)
        button3.center = CGPointMake(screenWidth / 2, button3.center.y)
        button4.center = CGPointMake(screenWidth / 2, button4.center.y)
        
        backgroundImage.frame = CGRectMake(0, 0, screenWidth, screenHeight)
        
    }
}

