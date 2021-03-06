//
//  ShopViewController.swift
//  BobaRunUI
//
//  Created by Hoa Pham on 5/22/16.
//  Copyright © 2016 Jessica Pham. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ShopViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    var tableView : UITableView!
    var shops = [String]()
    let shopViewCellReuseIdentifier = "shopViewCellReuseIdentifier"
    let buttonHeight = CGFloat(35)
    let buttonWidth = CGFloat(50)
    let buttonPadding = CGFloat(20)
    let footerHeight = CGFloat(80)
    let submitButtonHeight = CGFloat(50)
    
    var locationManager:CLLocationManager!
    var businesses = [Business]()
    
    var user = User()
    var roomName = ""
    
    init(roomName: String, user: User) {
        self.user = user
        self.roomName = roomName
        super.init(nibName: nil, bundle: nil)
    }
    
    required  init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func viewWillAppear(animated: Bool) {
        // TODO: backend yelp api to get array of boba shop names
        
        tableView = UITableView()
        let tableFrame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height-footerHeight)
        tableView = UITableView(frame: tableFrame, style: UITableViewStyle.Plain)
        tableView.registerClass(ShopTableViewCell.self, forCellReuseIdentifier: shopViewCellReuseIdentifier)
        tableView.allowsMultipleSelection = true
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(tableView)
        
        let footerView: UIView = UIView(frame: CGRectMake(0, CGRectGetMaxY(tableFrame), self.view.frame.width, footerHeight))
        footerView.backgroundColor = UIColor(red: 248/255, green: 241/255, blue: 243/255, alpha: 1)
        self.view.addSubview(footerView)
        
        let submitButton: UIButton = UIButton(frame: CGRectMake(0, CGRectGetMaxY(tableFrame), self.view.frame.width-30, submitButtonHeight))
        
        submitButton.center = footerView.center
        submitButton.setTitle("Continue", forState: UIControlState.Normal)
        submitButton.backgroundColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        submitButton.addTarget(self, action: #selector(ShopViewController.selectedContinueButton(_:)), forControlEvents: .TouchUpInside)
        submitButton.layer.cornerRadius = 5
        self.view.addSubview(submitButton)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.title = "Boba Shops"
        locationManager = CLLocationManager()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return businesses.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 85
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
//
//    func downloadImage(url: NSURL){
//        print("Download Started")
//        print("lastPathComponent: " + (url.lastPathComponent ?? ""))
//        getDataFromUrl(url) { (data, response, error)  in
//            dispatch_async(dispatch_get_main_queue()) { () -> Void in
//                guard let data = data where error == nil else { return }
//                print(response?.suggestedFilename ?? "")
//                print("Download Finished")
//                imageView.image = UIImage(data: data)
//            }
//        }
//    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(shopViewCellReuseIdentifier, forIndexPath: indexPath) as! ShopTableViewCell
    
        // TODO: shop object backend integration
        print("Download Started")
        print("lastPathComponent: " + (businesses[indexPath.row].imageURL!.lastPathComponent ?? ""))
        getDataFromUrl(businesses[indexPath.row].imageURL!) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                print(response?.suggestedFilename ?? "")
                print("Download Finished")
                cell.shopImageView.image = UIImage(data: data)
            }
        }
        // cell.shopImageView.image = UIImage(named: "love")
        cell.titleLabel.text = self.businesses[indexPath.row].name
        cell.ratingLabel.text = String("\(self.businesses[indexPath.row].reviewCount!) Reviews")
        getDataFromUrl(businesses[indexPath.row].ratingImageURL!) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                print(response?.suggestedFilename ?? "")
                print("Download Finished")
                cell.ratingImageView.image = UIImage(data: data)
            }
        }
        cell.addressLabel.text = self.businesses[indexPath.row].address
        // cell.descriptionLabel.text  = self.businesses[indexPath.row].categories

        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
         tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }
    
    func selectedContinueButton(sender: UIButton!) {
        let inviteViewController = NewRoomViewController(roomName: roomName, user: user)
        self.navigationController?.pushViewController(inviteViewController, animated: true)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        //        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        Business.searchWithTerm("Milk Tea", location: "\(locValue.latitude),\(locValue.longitude)", completion: { (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses = businesses
            
                for business in businesses {
                    print(business.name!)
                    print(business.address!)
                }
            
            if (businesses.count == 0) {
                print ("No businesses nearby.")
            }
            
            dispatch_async(dispatch_get_main_queue(),{
                self.tableView.reloadData()
            })
            
        })
        manager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print ("cannot get location, set default to San Francisco.")
        
        Business.searchWithTerm("Milk Tea", location: "37.785771,-122.406165", completion: { (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses = businesses
            
            for business in businesses {
                print(business.name!)
                print(business.address!)
            }
        })
        manager.stopUpdatingLocation()
    }
    
}
