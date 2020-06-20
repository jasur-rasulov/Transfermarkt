#'
#' Transfer record comparison of the Big Six to the rest of the Premier League.
#'

# DEPENDENCIES
if (!require("pacman")) install.packages("pacman")
pacman::p_load("data.table", "dplyr", "ggplot2", "readr", "showtext")
source("./src/01-clean.R")


# DATA
# Read for the 2010/11-2019/20 seasons
dirs <- dir("./data", pattern = "201\\d")
files <- file.path("./data", dirs, paste0("premier-league.csv"))
transfers <- files %>%
    lapply(read_csv) %>%
    rbindlist(use.names = TRUE) %>%
    tidy_transfers()


# ANALYSIS
# 03-1: Comparison of the Big Six to other Premeir League clubs
# Separate Big Six from the rest
big_six_names <- "Man United, Man City, Chelsea,\nLiverpool, Arsenal, Tottenham"
transfer_history <- transfers %>%
    filter(movement == "In" & (!is_loan | fee > 0)) %>%
    mutate(
        club = case_when(
            club == "Arsenal FC" ~ big_six_names,
            club == "Chelsea FC" ~ big_six_names,
            club == "Liverpool FC" ~ big_six_names,
            club == "Manchester City" ~ big_six_names,
            club == "Manchester United" ~ big_six_names,
            club == "Tottenham Hotspur" ~ big_six_names,
            TRUE ~ "Rest of Premier League"
        )
    ) %>%
    group_by(club, season) %>%
    summarize(expenditure = sum(fee, na.rm = TRUE)) %>%
    mutate(expenditure = expenditure / 1e6)

# Generate prop table for each group's proportion of total spending
df <- as.data.frame(transfer_history)
df <- df %>%
    reshape(
        idvar = "club",
        timevar = "season",
        v.names = "expenditure",
        direction = "wide"
    )
tab <- as.table(as.matrix(df[, -1]))
prop <- prop.table(tab, 2)

# 03-2: Individual club spending among the Big Six
big_six <- transfers %>%
    filter(movement == "In" & (!is_loan | fee > 0)) %>%
    filter(
        club == "Arsenal FC" |
        club == "Chelsea FC" |
        club == "Liverpool FC" |
        club == "Manchester City" |
        club == "Manchester United" |
        club == "Tottenham Hotspur"
    ) %>%
    mutate(
        club = case_when(
            club == "Arsenal FC" ~ "Arsenal",
            club == "Chelsea FC" ~ "Chelsea",
            club == "Liverpool FC" ~ "Liverpool",
            club == "Tottenham Hotspur" ~ "Tottenham",
            TRUE ~ club
        )
    ) %>%
    group_by(club, season) %>%
    summarize(expenditure = sum(fee, na.rm = TRUE)) %>%
    mutate(expenditure = expenditure / 1e6)


# VISUALIZATIONS
# Colors and fonts
league_colors <- c("#36003C", "#00FF87")
club_colors <- c(
    "#EF0107", # Arsenal
    "#034694", # Chelsea
    "#C8102E", # Liverpool
    "#6CABDD", # Manchester City
    "#DA291C", # Manchester United
    "#132257" # Tottenham
)
font_add_google("Open Sans", "Open Sans")
showtext_auto()

# 03-1: Comparison of the Big Six to other Premeir League clubs
viz_pl_comparison <- transfer_history %>%
    ggplot(aes(x = season, y = expenditure)) +
    geom_col(aes(y = expenditure, fill = club), position = "dodge") +
    labs(
        title = "League spending is catching up with the Big Six",
        subtitle = paste("The Big Six's proportion of Premier League transfer",
            "spending has steadily \ndeclined from its peak at 68.9% in 2010.",
            "Manchester City and Chelsea alone \naccounted for \u00A3520",
            "million of the record \u00A31.1 billion the Big Six spent in",
            "2017."),
        caption = "Source: Transfermarkt | @emordonez",
        x = "Season",
        y = "Total transfer expenditure (million \u00A3)"
    ) +
    guides(alpha = FALSE) +
    theme_minimal() +
    scale_x_continuous(breaks = transfer_history$season) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    scale_fill_manual(values = alpha(league_colors, 0.75)) +
    theme(
        legend.title = element_blank(),
        legend.position = c(0, 1),
        legend.justification = c(0, 1),
        plot.margin = margin(10, 10, 10, 10, "pt"),
        text = element_text(family = "Open Sans"),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(face = "plain"),
        plot.caption = element_text(face = "italic"),
        axis.title.x = element_text(margin = margin(7, 0, 0, 0, "pt")),
        axis.title.y = element_text(margin = margin(0, 7, 0, 0, "pt"))
    )
viz_pl_comparison

# 03-2: Individual club spending among the Big Six
viz_big_six <- big_six %>%
    ggplot(aes(x = season, y = expenditure, group = club)) +
    geom_area(aes(alpha = 0.75, fill = club)) +
    labs(
        title = "Three big spenders among the Big Six",
        subtitle = paste("The Manchester clubs and Chelsea won every league",
            "title in the decade save for the \n2015/16 and 2019/20 seasons.",
            "Each spent more than \u00A31 billion over 20 windows."),
        caption = "Source: Transfermarkt | @emordonez",
        x = "Season",
        y = "Total transfer expenditure (million \u00A3)"
    ) +
    theme_minimal() +
    scale_x_continuous(breaks = c(2010, 2012, 2014, 2016, 2018)) +
    scale_fill_manual(values = club_colors) +
    theme(
        legend.position = "none",
        plot.margin = margin(10, 10, 10, 10, "pt"),
        text = element_text(family = "Open Sans", face = "bold"),
        axis.title = element_text(face = "plain"),
        axis.text = element_text(face = "plain"),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(face = "plain"),
        plot.caption = element_text(face = "italic"),
        axis.title.x = element_text(margin = margin(7, 0, 0, 0, "pt")),
        axis.title.y = element_text(margin = margin(0, 7, 0, 0, "pt"))
    ) +
    facet_wrap(~club)
viz_big_six
