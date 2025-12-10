//
//  UpdateCell.swift
//  Latest
//
//  Created by Max Langer on 26.02.17.
//  Copyright © 2017 Max Langer. All rights reserved.
//

import Cocoa

/**
 The cell that is used in the list of available updates
 */
class UpdateCell: NSTableCellView {
	
	// MARK: - View Lifecycle
	
	/// The label displaying the current version of the app
	@IBOutlet private weak var nameTextField: NSTextField!

    /// The label displaying the current version of the app
    @IBOutlet private weak var currentVersionTextField: NSTextField!
    
    /// The label displaying the newest version available for the app
    @IBOutlet private weak var newVersionTextField: NSTextField!
	
	/// The stack view holding the cells contents.
	@IBOutlet private weak var contentStackView: NSStackView!
	
	/// The constraint defining the leading inset of the content.
	@available(macOS, deprecated: 11.0) @IBOutlet private weak var leadingConstraint: NSLayoutConstraint!
	
	/// Constraint controlling the trailing inset of the cell.
	@available(macOS, deprecated: 11.0) @IBOutlet private weak var trailingConstraint: NSLayoutConstraint!

	/// Label displaying the last modified/update date for the app.
	@IBOutlet private weak var dateTextField: NSTextField!
	
	/// The button handling the update of the app.
	@IBOutlet private weak var updateButton: UpdateButton!
	
	/// Image view displaying a status indicator for the support status of the app.
	@IBOutlet private weak var supportStateImageView: NSImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		if #available(macOS 11.0, *) {
			self.leadingConstraint.constant = 0;
			self.trailingConstraint.constant = 0;
		} else {
			self.leadingConstraint.constant = 20;
			self.trailingConstraint.constant = 20;
		}
	}
	
	
	// MARK: - Update Progress
	
	/// The app represented by this cell
	var app: App? {
		willSet {
			// Remove observer from existing app
			if let app = self.app {
				UpdateQueue.shared.removeObserver(self, for: app.identifier)
			}
		}
		
		didSet {
			if let app = self.app {
				UpdateQueue.shared.addObserver(self, to: app.identifier) { [weak self] progress in
					guard let self = self else { return }
					// Update state indicator visibility when update progress changes
					self.updateStateIndicator()
				}
			}

			self.updateButton.app = self.app
			self.updateContents()
		}
	}
	
	var filterQuery: String? {
		didSet {
			if filterQuery != oldValue {
				self.updateTitle()
			}
		}
	}
	
	
	// MARK: - Utilities
	
	/// A date formatter for preparing the update date.
	private lazy var dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.timeStyle = .none
		dateFormatter.dateStyle = .short
		dateFormatter.doesRelativeDateFormatting = true
		
		return dateFormatter
	}()
	
	private func updateContents() {
		guard let app = self.app, let versionInformation = app.localizedVersionInformation else { return }

		self.updateTitle()

		// Update the contents of the cell
        self.currentVersionTextField.stringValue = versionInformation.current
		self.newVersionTextField.stringValue = versionInformation.new ?? ""
        self.newVersionTextField.isHidden = !app.updateAvailable
		self.dateTextField.stringValue = dateFormatter.string(from: app.updateDate)

		// Update state indicator
		updateStateIndicator()
	}

	/// Updates the state indicator (ignored or support state).
	private func updateStateIndicator() {
		guard let app = self.app else {
			supportStateImageView.isHidden = true
			return
		}

		// State indicator: show ignored state or support state
		if app.isIgnored {
			// Show a distinct ignored indicator to differentiate from available updates
			supportStateImageView.isHidden = false
			if #available(macOS 11.0, *) {
				supportStateImageView.image = NSImage(systemSymbolName: "bell.slash.fill", accessibilityDescription: NSLocalizedString("IgnoredAppAccessibilityLabel", comment: "Accessibility label for ignored app indicator"))
				supportStateImageView.contentTintColor = .secondaryLabelColor
			} else {
				supportStateImageView.image = NSImage(named: NSImage.statusNoneName)
			}
			supportStateImageView.toolTip = NSLocalizedString("IgnoredAppTooltip", comment: "Tooltip for ignored app indicator")
		} else {
			// Support state
			supportStateImageView.isHidden = !showSupportState
			if showSupportState {
				supportStateImageView.image = app.source.supportState.statusImage
				if #available(macOS 11.0, *) {
					supportStateImageView.contentTintColor = nil
				}
				supportStateImageView.toolTip = app.source.supportState.label
			}
		}
	}
	
	/// Whether the status indicator for the apps support state should be visible.
	private var showSupportState: Bool {
		guard let app else { return false }
		
		let isUpdating = switch UpdateQueue.shared.state(for: app.identifier) {
		case .none, .error: false
		default : true
		}
		
		return !isUpdating && (AppListSettings.shared.includeAppsWithLimitedSupport || AppListSettings.shared.includeUnsupportedApps)
	}
	    
	private func updateTitle() {
		self.nameTextField.attributedStringValue = self.app?.highlightedName(for: self.filterQuery) ?? NSAttributedString()
	}
}
