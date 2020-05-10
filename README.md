# Web Scraping Football Transfer Data from Transfermarkt

This is a Python script that scrapes league transfer histories from Transfermarkt using BeautifulSoup and Pandas. 

## Data

The scraped data are written to csv's in subfolders, labeled by year, of the `data` folder. This repository has data from 1992-2018 for the English Premier League and Championship to demonstrate how the script can scrape multiple leagues and seasons.

### Variables

| Label              | Description                                                                                           |
|--------------------|-------------------------------------------------------------------------------------------------------|
| `Club`             | Club involved in the transfer, i.e. the buyer/seller                                                  |
| `Name`             | Player's name                                                                                         |
| `Age`              | Player's age at the date of the transfer                                                              |
| `Nat.`             | Player's nationality, per FIFA international eligibility                                              |
| `Position`         | Player's position                                                                                     |
| `Pos`              | Abbreviated `Position`, e.g. _CF_ for centre-forward                                                  |
| `Market value`     | Transfermarkt's estimated market value of the player                                                  |
| `Club involved`    | Other club involved in the transfer, i.e. the seller/buyer                                            |
| `Country involved` | Country in which the other `Club involved` competes                                                   |
| `Fee`              | Transfer fee in nominal GBP                                                                           |
| `Movement`         | _In_ if the `Club` is buying this player, _Out_ if they're selling                                    |
| `Season`           | First year of the season in which the transfer takes place, e.g. _2018_ for the 2018-19 season        |
| `Window`           | Window in which the transfer takes place, i.e. summer or winter                                       |
| `League`           | `Club`'s league                                                                                       |

### Cleaning

Note that dataframe entries are given as _-_ when "not applicable" and _?_ when unknown. Entries under the `Fee` label can include:

* _Loan_
* _Loan fee:_ + Amount
* _End of loan_ + Date
* _Free transfer_

## Source

All data are scraped from [Transfermarkt](https://www.transfermarkt.co.uk/) according to their [terms of use](https://www.transfermarkt.co.uk/intern/anb).
