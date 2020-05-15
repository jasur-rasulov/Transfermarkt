# Transfermarket Transfer Data

Web-scraped data of all transfers from the 1992/93 to 2019/20 seasons of the top five European leagues:

* Premier League
* Bundesliga
* La Liga
* Serie A
* Ligue 1

## Data

Each league's records are saved in season subdirectories of `data`. The Python script used to scrape the data is included in `src`.

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

Note that entries are recorded as _"-"_ when "not applicable" and _"?"_ when unknown. Non-numeric entries under the `Fee` label include:

* _Loan_
* _Loan fee:_ + Amount
* _End of loan_ + Date
* _Free transfer_

### Examples

Example R scripts to tidy and analyze the data are included in `src`. The resulting images are included in `figure`.

## Source

All data are scraped from [Transfermarkt](https://www.transfermarkt.co.uk/) according to their [terms of use](https://www.transfermarkt.co.uk/intern/anb).
