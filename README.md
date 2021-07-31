# currency-exchange-app

This application uses the currencylayer API (https://currencylayer.com/) to offer the possibility to the user to convert different amounts from one currency to another.

To use it you need to have internet at list once to download the currency related data, at the start of the app or by pressing initial screen right bar button.

Once the data is downloaded, it is saved and it can be used until you uninstall the app.

The data is downloaded again and overwritten everytime you start the app or press on the refresh button having connection.

Next step would be to choose both currencies, the one to introduce the amount and the one to recive the converted amount, by clicking on them and choose a currency in the table view that appears.

Both amount text fields can be used to introduce an amount, and the conversion then takes place in the other text field.

To handle the local storage I have used Core Data.

For parsing json responses I have used SwiftyJSON.

For parsing html response data I have used Kanna.

To show progress to the user while fetching the data I have used JGProgressHUD.

The app is very easy to use and to understand, I hope you enjoy :)
