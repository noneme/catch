import AppKit


class RecentsController: NSWindowController {
  @IBOutlet private weak var table: NSTableView!
  
  fileprivate let downloadDateFormatter = DateFormatter()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Configure formatter for torrent download dates
    downloadDateFormatter.timeStyle = .short
    downloadDateFormatter.dateStyle = .short
    downloadDateFormatter.doesRelativeDateFormatting = true
    
    // Subscribe to history changes
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name(rawValue: kCTCSchedulerStatusChangedNotificationName),
      object: CTCScheduler.shared(),
      queue: nil,
      using: { [weak self] _ in
        self?.table.reloadData()
      }
    )
  }
  
  @IBAction override func showWindow(_ sender: Any?) {
    table.reloadData()
    NSApp.activate(ignoringOtherApps: true)
    super.showWindow(sender)
  }
  
  @IBAction private func downloadRecentItemAgain(_ senderButton: NSButton) {
    let clickedRow = table.row(for: senderButton)
    let recentToDownload = CTCDefaults.downloadHistory()[clickedRow]
    let isMagnetLink = recentToDownload["isMagnetLink"] as! Bool
    if isMagnetLink {
      CTCBrowser.open(inBackgroundURL: URL(string: recentToDownload["url"] as! String)!)
    }
    else {
      CTCScheduler.shared().downloadFile(recentToDownload) { downloadedFile, error in
        guard CTCDefaults.shouldOpenTorrentsAutomatically(), let downloadedFile = downloadedFile else {
          return
        }
        CTCBrowser.open(inBackgroundFile: downloadedFile["torrentFilePath"] as! String)
      }
    }
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

extension RecentsController: NSTableViewDataSource {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return CTCDefaults.downloadHistory().count
  }
}

extension RecentsController: NSTableViewDelegate {
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let recent = CTCDefaults.downloadHistory()[row]
    
    guard let cell = tableView.make(withIdentifier: "RecentCell", owner: self) as? RecentsCellView else {
      return nil
    }
    
    cell.textField?.stringValue = recent["title"] as! String
    
    let downloadDate = recent["date"] as? Date
    cell.downloadDateTextField.stringValue = downloadDate.map(downloadDateFormatter.string) ?? ""
    
    return cell
  }
  
  func selectionShouldChange(in tableView: NSTableView) -> Bool {
    return false
  }
}