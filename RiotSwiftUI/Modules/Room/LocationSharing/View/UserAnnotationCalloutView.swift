// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Mapbox

class UserAnnotationCalloutView: UIView, MGLCalloutView, Themable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.2
        static let bottomMargin: CGFloat = 3.0
    }
 
    // MARK: - Properties
    
    // MARK: Overrides
    
    var representedObject: MGLAnnotation
    
    lazy var leftAccessoryView: UIView = UIView()
    
    lazy var rightAccessoryView: UIView = UIView()
    
    var delegate: MGLCalloutViewDelegate?
    
    // Allow the callout to remain open during panning.
    let dismissesAutomatically: Bool = false
    
    let isAnchoredToAnnotation: Bool = true
    
    // https://github.com/mapbox/mapbox-gl-native/issues/9228
    override var center: CGPoint {
        set {
            var newCenter = newValue
            newCenter.y -= bounds.maxY + Constants.bottomMargin
            super.center = newCenter
        }
        get {
            return super.center
        }
    }
    
    // MARK: Private
    
    lazy var contentView: UserAnnotationCalloutContentView = {
        return UserAnnotationCalloutContentView.instantiate()
    }()
    
    // MARK: - Setup
    
    required init(userLocationAnnotation: UserLocationAnnotation) {
        
        self.representedObject = userLocationAnnotation
        
        super.init(frame: .zero)
                        
        self.vc_addSubViewMatchingParent(self.contentView)
        
        self.update(theme: ThemeService.shared().theme)
        
        let size = UserAnnotationCalloutContentView.contentViewSize()

        self.frame = CGRect(origin: .zero, size: size)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.contentView.update(theme: theme)
    }
    
    // MARK: - Overrides

    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        
        // Set callout above the marker view
        
        self.center = view.center.applying(CGAffineTransform(translationX: 0, y: view.bounds.height/2 + self.bounds.height))
        
        delegate?.calloutViewWillAppear?(self)
        
        view.addSubview(self)
        
        if isCalloutTappable() {
            // Handle taps and eventually try to send them to the delegate (usually the map view).
            self.contentView.shareButton.addTarget(self, action: #selector(CustomCalloutView.calloutTapped), for: .touchUpInside)
        } else {
            // Disable tapping and highlighting.
            self.contentView.shareButton.isUserInteractionEnabled = false
        }
        
        if animated {
            alpha = 0
            
            UIView.animate(withDuration: Constants.animationDuration) { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.alpha = 1
                strongSelf.delegate?.calloutViewDidAppear?(strongSelf)
            }
        } else {
            delegate?.calloutViewDidAppear?(self)
        }
    }
    
    func dismissCallout(animated: Bool) {
        if (superview != nil) {
            if animated {
                UIView.animate(withDuration: Constants.animationDuration, animations: { [weak self] in
                    self?.alpha = 0
                }, completion: { [weak self] _ in
                    self?.removeFromSuperview()
                })
            } else {
                removeFromSuperview()
            }
        }
    }

    // MARK: - Callout interaction handlers

    func isCalloutTappable() -> Bool {
        if let delegate = delegate {
            if delegate.responds(to: #selector(MGLCalloutViewDelegate.calloutViewShouldHighlight)) {
                return delegate.calloutViewShouldHighlight!(self)
            }
        }
        return false
    }

    @objc func calloutTapped() {
        if isCalloutTappable() && delegate!.responds(to: #selector(MGLCalloutViewDelegate.calloutViewTapped)) {
            delegate!.calloutViewTapped!(self)
        }
    }
}