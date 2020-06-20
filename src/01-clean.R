#'
#' Functions to clean scraped Transfermarkt data.
#'

# Dependencies
if (!require("pacman")) install.packages("pacman")
pacman::p_load("dplyr", "readr", "stringi")

#' Cleans the input dataframe. Introduces a boolean label for if on loan and
#' character label for loan status/description.
#'
#' @param df The dataframe to be tidied.
#'
#' @return The tidied dataframe.
#'
tidy_transfers <- function(df) {
    # Helper function to convert currency values from characters to numerics
    value_as_numeric <- function(val) {
        if (is.na(val) || val == "-" || val == "?") {
            val <- NA_real_
        } else if (stri_sub(val, -1, -1) == "m") {
            val <- as.numeric(stri_sub(val, 2, -2)) * 1000000
        } else if (stri_sub(val, -3, -1) == "Th.") {
            val <- as.numeric(stri_sub(val, 2, -4)) * 1000
        } else {
            val <- as.numeric(stri_sub(val, 2, -1))
        }
        return(val)
    }

    # Helper function to set loan status based on fee
    format_fees_and_loans <- function(fee, movement, is_loan, loan_status) {
        if (!is.na(fee)) {
            if (startsWith(fee, "End of loan")) {
                is_loan <- TRUE
                loan_status <- if_else(movement == "In",
                                        "Returning from loan", "End of loan")
                fee <- "$0"
            } else if (startsWith(fee, "Loan fee")) {
                is_loan <- TRUE
                loan_status <- if_else(movement == "In",
                                        "Loan in", "Loan out")
                fee <- gsub("Loan fee:", "", fee)
            } else if (fee == "Loan") {
                is_loan <- TRUE
                loan_status <- if_else(movement == "In",
                                        "Loan in", "Loan out")
                fee <- "$0"
            } else if (fee == "Free transfer") {
                fee <- "$0"
            }
        }
        return(list("fee" = fee,
                    "is_loan" = is_loan,
                    "loan_status" = loan_status))
    }

    # Rename columns, format league and window, initialize loan status
    transfers <- df %>%
        rename(
            club = "Club",
            name = "Name",
            age = "Age",
            nationality = "Nationality",
            position = "Position",
            pos = "Pos",
            market_value = "MarketValue",
            club_of_transfer = "ClubInvolved",
            country_of_transfer = "CountryInvolved",
            fee = "Fee",
            movement = "Movement",
            season = "Season",
            window = "Window",
            league = "League",
            profile = "Profile"
        ) %>%
        mutate(
            age = as.integer(age),
            season = as.integer(season),
            league = stri_trans_totitle(gsub("-", " ", league)),
            window = if_else(window == "s", "Summer", "Winter"),
            is_loan = FALSE,
            loan_status = NA_character_
        )

    # Temporary dataframe to hold formatted columns
    tidy_fee_and_loan <- bind_rows(mapply(format_fees_and_loans,
                                            transfers$fee,
                                            transfers$movement,
                                            transfers$is_loan,
                                            transfers$loan_status,
                                            SIMPLIFY = FALSE))

    # Update fee and loan status, convert fee and market value to numerics
    transfers <- transfers %>%
        mutate(
            fee = tidy_fee_and_loan$fee,
            is_loan = tidy_fee_and_loan$is_loan,
            loan_status = tidy_fee_and_loan$loan_status
        ) %>%
        mutate(
            market_value = sapply(market_value, value_as_numeric),
            fee = sapply(fee, value_as_numeric)
        )

    return(transfers)
}
