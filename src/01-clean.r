#'
#' Functions to clean scraped Transfermarkt data.
#'

# Dependencies
if (!require("pacman")) install.packages("pacman")
pacman::p_load("dplyr", "readr", "stringi")

#' Cleans the input dataframe. Introduces a boolean label for loan status.
#'
#' @param df The dataframe to be tidied.
#'
#' @return The tidied dataframe.
#'
tidy_transfers <- function(df) {
    # Helper function to convert currency values from characters to numerics
    value_as_numeric <- function(val) {
        if (val == "-" || val == "?") {
            x <- NA_real_
        } else if (stri_sub(val, -1, -1) == "m") {
            x <- as.numeric(stri_sub(val, 2, -2)) * 1000000
        } else if (stri_sub(val, -1, -1) == "k") {
            x <- as.numeric(stri_sub(val, 2, -2)) * 1000
        } else {
            x <- as.numeric(stri_sub(val, 2, -1))
        }
        return(x)
    }

    # Helper function to set loan status based on fee
    format_fees_and_loans <- function(fee, is_loan) {
        if (startsWith(fee, "End of loan")) {
            is_loan <- TRUE
            fee <- "$0"
        } else if (startsWith(fee, "Loan fee")) {
            is_loan <- TRUE
            fee <- gsub("Loan fee:", "", fee)
        } else if (fee == "Loan") {
            is_loan <- TRUE
            fee <- "$0"
        } else if (fee == "Free transfer") {
            fee <- "$0"
        }
        return(list("fee" = fee, "is_loan" = is_loan))
    }

    # Rename columns, format league and window, initialize loan status
    transfers <- df %>%
        rename(
            club = "Club",
            name = "Name",
            age = "Age",
            nationality = "Nat.",
            position = "Position",
            pos = "Pos",
            market_value = "Market value",
            club_of_transfer = "Club involved",
            country_of_transfer = "Country involved",
            fee = "Fee",
            movement = "Movement",
            season = "Season",
            window = "Window",
            league = "League"
        ) %>%
        mutate(
            league = stri_trans_totitle(gsub("-", " ", league)),
            window = ifelse(window == "s", "Summer", "Winter"),
            is_loan = FALSE
        )

    # Temporary dataframe to hold formatted columns
    tidy_fee_and_loan <- bind_rows(mapply(format_fees_and_loans,
                                            transfers$fee, transfers$is_loan,
                                            SIMPLIFY = FALSE))

    # Update fee and loan status, convert fee and market value to numerics
    transfers <- transfers %>%
        mutate(
            fee = tidy_fee_and_loan$fee,
            is_loan = tidy_fee_and_loan$is_loan
        ) %>%
        mutate(
            market_value = sapply(market_value, value_as_numeric),
            fee = sapply(fee, value_as_numeric)
        )

    return(transfers)
}
