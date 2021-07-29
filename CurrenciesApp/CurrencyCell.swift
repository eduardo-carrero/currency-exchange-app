//
//  CurrencyCell.swift
//  CurrenciesApp
//
//  Created by Eduardo Carrero Yubero on 29/7/21.
//

import UIKit

class CurrencyCell: UITableViewCell {
    
    @IBOutlet weak var flagImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(quote: Quote) {
        print("\(#function)")
        nameLabel.text = quote.name
        descriptionLabel.text = quote.currencyDescription
        var image = UIImage(named: quote.name.lowercased())
        if image == nil {
            image = UIImage(named: "ic-no-image")
        }
        flagImage.image = image
    }
}
