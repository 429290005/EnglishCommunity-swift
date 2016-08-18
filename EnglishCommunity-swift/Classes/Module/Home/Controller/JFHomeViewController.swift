//
//  JFHomeViewController.swift
//  EnglishCommunity-swift
//
//  Created by zhoujianfeng on 16/8/4.
//  Copyright © 2016年 zhoujianfeng. All rights reserved.
//

import UIKit
import SDCycleScrollView
import MJRefresh
import SwiftyJSON

class JFHomeViewController: UIViewController {
    
    let categoriesIdentifier = "categoriesIdentifier"
    let homeCellIdentifier = "homeCellIdentifier"
    
    /// 顶部轮播视图
    var topScrollView: SDCycleScrollView?
    var topVideoInfos = [JFVideoInfo]()
    
    /// 所有分类信息模型
    var videoCategories = [JFVideoCategory]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareUI()
        tableView.mj_header = setupHeaderRefresh(self, action: #selector(updateHomeData))
        tableView.mj_header.beginRefreshing()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        topScrollView?.adjustWhenControllerViewWillAppera()
    }
    
    /**
     准备UI
     */
    private func prepareUI() {
        
        view.backgroundColor = COLOR_ALL_BG
        tableView.backgroundColor = COLOR_ALL_BG
        view.addSubview(tableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.rightItem("navigation_search_icon", highlightedImage: "navigation_search_icon_selected", target: self, action: #selector(didTappedSearchButton))
    }
    
    /**
     准备顶部轮播
     */
    private func prepareScrollView() {
        
        topScrollView = SDCycleScrollView(frame: CGRect(x:0, y:0, width: SCREEN_WIDTH, height: 188), delegate: self, placeholderImage: UIImage(named: "photoview_image_default_white"))
        topScrollView?.pageControlAliment = SDCycleScrollViewPageContolAlimentCenter
        topScrollView?.pageControlStyle = SDCycleScrollViewPageContolStyleAnimated
        
        var images = [String]()
        for model in topVideoInfos {
            images.append(model.cover!)
        }
        
        topScrollView?.imageURLStringsGroup = images
        topScrollView?.autoScrollTimeInterval = 5
        tableView.tableHeaderView = topScrollView
        
    }
    
    /**
     点击了搜索按钮
     */
    @objc private func didTappedSearchButton() {
        
    }
    
    /**
     刷新首页数据
     */
    @objc private func updateHomeData() {
        loadTopData()
        loadCategoriesData()
    }
    
    /**
     加载顶部轮播数据
     */
    private func loadTopData() {
        
        JFVideoInfo.loadVideoInfoList(1, count: 4, category_id: 0, recommend: 1) { (videoInfos) in
            guard let videoInfos = videoInfos else {
                return
            }
            
            self.topVideoInfos = videoInfos
            self.prepareScrollView()
            
        }
    }
    
    /**
     加载所有分类数据
     */
    private func loadCategoriesData() {
        
        JFVideoCategory.loadAllCategories(1, count: 4) { (videoCategories) in
            
            self.tableView.mj_header.endRefreshing()
            
            guard let videoCategories = videoCategories else {
                return
            }
            
            self.videoCategories = videoCategories
            self.tableView.reloadData()
        }
    }
    
    /// 内容区域
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT - 60), style: UITableViewStyle.Plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.whiteColor()
        tableView.separatorColor = UIColor(red:0.9,  green:0.9,  blue:0.9, alpha:1)
        tableView.registerClass(JFCategoriesCell.self, forCellReuseIdentifier: self.categoriesIdentifier)
        tableView.registerClass(JFHomeCell.self, forCellReuseIdentifier: self.homeCellIdentifier)
        return tableView
    }()
    
}

// MARK: - SDCycleScrollViewDelegate
extension JFHomeViewController: SDCycleScrollViewDelegate {
    
    func cycleScrollView(cycleScrollView: SDCycleScrollView!, didSelectItemAtIndex index: Int) {
        
        // 进入播放页面
        let playerVc = JFPlayerViewController()
        playerVc.videoInfo = topVideoInfos[index]
        navigationController?.pushViewController(playerVc, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension JFHomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // 分类 + 1个分类综合
        return videoCategories.count + 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 87
        } else {
            return LIST_ITEM_HEIGHT * 2 + LIST_ITEM_PADDING
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.01
        }
        return 40
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section != 0 {
            let headerView = NSBundle.mainBundle().loadNibNamed("JFHomeSectionHeaderView", owner: nil, options: nil).last as! JFHomeSectionHeaderView
            headerView.titleLabel.text = videoCategories[section - 1].name
            headerView.section = section
            headerView.delegate = self
            headerView.moreButton.hidden = false
            return headerView
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(categoriesIdentifier) as! JFCategoriesCell
            cell.delegate = self
            cell.videoCategories = videoCategories
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(homeCellIdentifier) as! JFHomeCell
            cell.videoCategory = videoCategories[indexPath.section - 1]
            cell.delegate = self
            return cell
        }
    }
    
}

// MARK: - JFCategoriesCellDelegate, JFHomeCellDelegate
extension JFHomeViewController: JFCategoriesCellDelegate, JFHomeCellDelegate {
    
    /**
     点击了顶部横向滑动分类的item
     
     - parameter cell:      所在的cell
     - parameter indexPath: 点击的cell内部collectionView的indexPath
     */
    func categoriesCell(cell: UITableViewCell, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let categoryVc = JFCategoryViewController()
        categoryVc.category = videoCategories[indexPath.row]
        navigationController?.pushViewController(categoryVc, animated: true)
    }
    
    /**
     点击了首页视频的item
     
     - parameter cell:      所在的cell
     - parameter indexPath: 点击的cell内部collectionView的indexPath
     */
    func homeCell(cell: UITableViewCell, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cellIndexPath = tableView.indexPathForCell(cell)!
        
        // 进入播放页面
        let playerVc = JFPlayerViewController()
        playerVc.videoInfo = videoCategories[cellIndexPath.section - 1].videoInfos![indexPath.item]
        navigationController?.pushViewController(playerVc, animated: true)
    }
    
}

// MARK: - JFHomeSectionHeaderViewDelegate
extension JFHomeViewController: JFHomeSectionHeaderViewDelegate {
    
    /**
     点击了更多按钮
     */
    func didTappedMoreButton(section: Int) {
        let categoryVc = JFCategoryViewController()
        categoryVc.category = videoCategories[section - 1]
        navigationController?.pushViewController(categoryVc, animated: true)
    }
}

