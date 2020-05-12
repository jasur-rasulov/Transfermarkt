#'
#'  Premier League spending comparisons for the 2019/20 transfer windows.
#'

# Dependencies
if (!require("pacman")) install.packages("pacman")
pacman::p_load("dplyr", "readr", "ggplot2", "showtext")
source("./src/01-clean.R")

pl_2019 <- read_csv("./data/2019/premier-league.csv") %>% tidy_transfers()

# Look only at movements with a fee
transfers <- pl_2019 %>% filter(!is_loan | fee > 0)

club_spending <- transfers %>%
    filter(movement == "In") %>%
    group_by(club) %>%
    summarise(expenditure = sum(fee, na.rm = TRUE)) %>%
    mutate(expenditure = expenditure / 1000000)

club_sales <- transfers %>%
    filter(movement == "Out") %>%
    group_by(club) %>%
    summarise(income = sum(fee, na.rm = TRUE)) %>%
    mutate(income = income / 1000000)

club_record <- merge(club_spending, club_sales) %>%
    mutate(profit = income - expenditure)

# Update names
club_record$club <- c(
    "Bournemouth",
    "Arsenal",
    "Aston Villa",
    "Brighton",
    "Burnley",
    "Chelsea",
    "Crystal Palace",
    "Everton",
    "Leicester City",
    "Liverpool",
    "Manchester City",
    "Manchester United",
    "Newcastle",
    "Norwich",
    "Sheffield United",
    "Southampton",
    "Tottenham",
    "Watford",
    "West Ham",
    "Wolves"
)

# Club colors and fonts for graphics
# Definitions from https://teamcolorcodes.com/
club_record$color <- c(
    "#EF0107", # Arsenal
    "#670E36", # Aston Villa
    "#B50E12", # Bournemouth
    "#0057B8", # Brighton
    "#6C1D45", # Burnley
    "#034694", # Chelsea
    "#1B458F", # Crystal Palace
    "#003399", # Everton
    "#003090", # Leicester City
    "#C8102E", # Liverpool
    "#6CABDD", # Manchester City
    "#DA291C", # Manchester United
    "#241F20", # Newcastle
    "#FFF200", # Norwich
    "#EE2737", # Sheffield United
    "#D71920", # Southampton
    "#132257", # Tottenham
    "#FBEE23", # Watford
    "#7A263A", # West Ham
    "#FDB913" # Wolves
)

font_add_google("Open Sans", "Open Sans")
showtext_auto()

# Visualizations
# Total club expenditures
viz_spending <- club_record %>%
    ggplot(aes(x = reorder(club, expenditure), y = expenditure)) +
    geom_col(aes(alpha = 0.75, fill = club)) +
    geom_text(
        aes(label = sprintf("%0.2f", expenditure), hjust = -0.2),
        size = 3.5
    ) +
    labs(
        title = "Premier League transfer spending by club",
        subtitle = paste("For the 2019/20 season, transfer spending in the",
            "summer and winter \nwindows totaled more than \u00A31.59",
            "billion."),
        caption = "Source: Transfermarkt | @emordonez",
        x = NULL,
        y = "Total transfer expenditure (million \u00A3)"
    ) +
    theme_minimal() +
    scale_fill_manual(values = club_record$color) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    theme(
        legend.position = "none",
        plot.margin = margin(10, 10, 10, 10, "pt"),
        text = element_text(family = "Open Sans"),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(face = "plain"),
        plot.caption = element_text(face = "italic"),
        axis.title.x = element_text(margin = margin(5, 0, 0, 0, "pt")),
        axis.line.y = element_line(color = "black", size = 0.5, linetype = 1)
    ) +
    coord_flip()
viz_spending

# Net transfer spending
viz_profits <- club_record %>%
    ggplot(aes(x = reorder(club, profit), y = profit)) +
    geom_col(aes(alpha = 0.75, fill = club)) +
    geom_text(
        aes(
            label = sprintf("%0.2f", profit),
            y = 0,
            hjust = if_else(profit > 0, 1.2, -0.2)
        ),
        size = 3.5
    ) +
    labs(
        title = "Net transfer spending for the 2019/20 season",
        subtitle = paste("Premier League clubs raked in over \u00A3790",
            "million in transfer income. \nChelsea's transfer ban and sale of",
            "Eden Hazard to Real Madrid for\n\u00A390 million saw them top",
            "the league in income and profit."),
        caption = "Source: Transfermarkt | @emordonez",
        x = NULL,
        y = "Net transfer value (million \u00A3)"
    ) +
    theme_minimal() +
    scale_fill_manual(values = club_record$color) +
    theme(
        legend.position = "none",
        plot.margin = margin(10, 10, 10, 10, "pt"),
        text = element_text(family = "Open Sans"),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(face = "plain"),
        plot.caption = element_text(face = "italic"),
        axis.title.x = element_text(margin = margin(5, 0, 0, 0, "pt"))
    ) +
    coord_flip()
viz_profits
