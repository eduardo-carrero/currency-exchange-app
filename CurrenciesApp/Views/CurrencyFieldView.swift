//
//  CurrencyFieldView.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 30/7/21.
//

import UIKit

class CurrencyFieldView: UIView {
    
    private(set) var quote: Quote?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    var selectCurrencyAction: ((CurrencyFieldView) -> Void)?
    
    
    @IBAction func didTapCurrencyView(_ sender: Any) {
        print("\(#function)")
        selectCurrencyAction?(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    private func initSubviews() {
        // standard initialization logic
        let nib = UINib(nibName: "CurrencyFieldView", bundle: nil)
        nib.instantiate(withOwner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
    }
    
    func configure(withQuote quote: Quote) {
        self.quote = quote
        nameLabel.text = quote.name
        descriptionLabel.text = quote.currencyDescription
        imageView.image = UIImage(named: quote.name.lowercased())
    }

}
