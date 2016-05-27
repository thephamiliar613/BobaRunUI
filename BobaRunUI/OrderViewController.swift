//
//  OrderViewController.swift
//  BobaRun
//
//  Created by Hoa Pham on 5/2/16.
//  Copyright (c) 2016 Jessica Pham. All rights reserved.
//

import UIKit
import CoreData

class OrderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var room : Room!
    var user : User!
    var order : Order!
    var tableView : UITableView!
    var orders = [Order]()
    let orderViewCellReuseIdentifier = "orderViewCellReuseIdentifier"
    let footerHeight = CGFloat(80)
    let submitButtonHeight = CGFloat(50)
    
    init(room: Room, user: User) {
        self.room = room
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required  init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.title = "Orders"
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(OrderViewController.addNewOrder(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        
        // TODO: populate orders from Backend
        BobaRunAPI.bobaRunSharedInstance.getRoomOrders(room.roomID!) { (json: JSON) in
            print ("getting orders")
            if let creation_error = json["error"].string {
                if creation_error == "true" {
                    print ("could not get orders")
                }
                else {
                    if let results = json["result"].array {
                        self.orders.removeAll()
                        for entry in results {
                            var temp_order = Order(json: entry)
                        BobaRunAPI.bobaRunSharedInstance.getUserWithId(String(temp_order.userId)) { (json: JSON) in
                                print ("getting user info")
                                if let creation_error = json["error"].string {
                                    if creation_error == "true" {
                                        print ("could get user info")
                                    }
                                    else {
                                        if let results = json["result"].array {
                                            for entry in results {
                                                temp_order.user = (User(json: entry))
                                            }
                                            dispatch_async(dispatch_get_main_queue(),{
                                                self.tableView.reloadData()
                                            })
                                        }
                                    }
                                }
                            }
                            self.orders.append(temp_order)
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(),{
                    self.tableView.reloadData()
                    })
                }
            }
        }

//                var order1 = Order()
//        order1.iceLevel = "50%"
//        order1.toppings = ["Boba", "Pudding"]
//        order1.sugarLevel = "50%"
//        order1.teaType = "Milk Tea"
//        let testFriend = User()
//        testFriend.firstName = "Jessica"
//        testFriend.lastName = "Pham"
//        testFriend.username = "jmpham613"
//        testFriend.image = UIImage(named: "faithfulness")!
//        order1.user = testFriend
//        orders = [order1]
//        orders.sortInPlace({ $0.userId < $1.userId })
        
        // user is runner
        if (room.runner == NSUserDefaults.standardUserDefaults().stringForKey("USERNAME")) {
            tableView = UITableView()
            let tableFrame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height-footerHeight)
            tableView = UITableView(frame: tableFrame, style: UITableViewStyle.Plain)
            tableView.registerClass(OrderViewTableViewCell.self, forCellReuseIdentifier: orderViewCellReuseIdentifier)
            tableView.allowsMultipleSelection = true
            tableView.delegate = self
            tableView.dataSource = self
            self.view.addSubview(tableView)
            
            let footerView: UIView = UIView(frame: CGRectMake(0, CGRectGetMaxY(tableFrame), self.view.frame.width, footerHeight))
            footerView.backgroundColor = UIColor(red: 248/255, green: 241/255, blue: 243/255, alpha: 1)
            self.view.addSubview(footerView)
            
            let confirmButton: UIButton = UIButton(frame: CGRectMake(0, CGRectGetMaxY(tableFrame), self.view.frame.width-30, submitButtonHeight))
            confirmButton.center = footerView.center
            confirmButton.setTitle("Confirm", forState: UIControlState.Normal)
            confirmButton.backgroundColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
            confirmButton.addTarget(self, action: #selector(OrderViewController.selectedConfirmButton(_:)), forControlEvents: .TouchUpInside)
            confirmButton.layer.cornerRadius = 5
            self.view.addSubview(confirmButton)
            
        // user is member
        } else {
            tableView = UITableView()
            tableView = UITableView(frame: self.view.frame, style: UITableViewStyle.Plain)
            tableView.registerClass(OrderViewTableViewCell.self, forCellReuseIdentifier: orderViewCellReuseIdentifier)
            tableView.delegate = self
            tableView.dataSource = self
            self.view.addSubview(tableView)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(100)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let order = orders[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier(orderViewCellReuseIdentifier) as! OrderViewTableViewCell
        if (order.user.firstName != nil) {
            cell.userLabel.text = order.user.firstName! + " " + order.user.lastName!
        }
        cell.priceLabel.text = "$3.25" // TODO : add price to orders
        cell.teaTypeLabel.text = "Tea Type: " + order.teaType
        cell.sugarLevelLabel.text = "Sugar Level: " + order.sugarLevel
        cell.iceLevelLabel.text = "Ice Level: " + order.iceLevel
        
        if (order.toppings.count > 0) {
            var toppingsText = "Toppings: " + order.toppings[0]
            var index = 1
            while (index < order.toppings.count) {
                toppingsText = toppingsText + ", " + order.toppings[index]
                index += 1
            }
            cell.toppingsLabel.text = toppingsText
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.order = orders[indexPath.row]
        if (room.runner == NSUserDefaults.standardUserDefaults().stringForKey("USERNAME") && !room.confirmed) {
            tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else if (order.user == NSUserDefaults.standardUserDefaults().stringForKey("USERNAME") && room.confirmed) {
            let payOrderViewController = PayOrderViewController(order: order)
            self.navigationController?.pushViewController(payOrderViewController, animated: true)
        } else {
            let confirmationViewController = OrderConfirmationViewController(order: self.order, room: self.room, user: self.user, confirmButton: false)
            self.navigationController?.pushViewController(confirmationViewController, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if (room.runner == NSUserDefaults.standardUserDefaults().stringForKey("USERNAME") && !room.confirmed) {
            tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
        }
    }
    
    func addNewOrder(sender: AnyObject) {
        let orderFormViewController = OrderFormViewController(user: self.user, room: self.room)
        self.navigationController?.pushViewController(orderFormViewController, animated: true)
    }
    
    func selectedConfirmButton(sender: UIButton!) {
        // TODO: change room to confirmed in backend
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}
