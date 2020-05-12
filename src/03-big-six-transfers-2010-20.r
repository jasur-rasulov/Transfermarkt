#'
#' Transfer record comparison of the big six to the rest of the Premier League.
#'

# Dependencies
if (!require("pacman")) install.packages("pacman")
pacman::p_load("dplyr", "readr", "data.table", "ggplot2", "showtext")
source("./src/01-clean.R")

# Read data
dirs <- dir("./data", pattern = "201\\d")
files <- file.path("./data", dirs, paste0("premier-league.csv"))
data <- lapply(files, read_csv)
transfers <- rbindlist(data, use.names = TRUE) %>% tidy_transfers()

# Separate big six from rest of the league
transfer_history <- transfers %>%
    filter(movement == "In" & (!is_loan | fee > 0)) %>%
    mutate(
        club = case_when(
            club == "Arsenal FC" ~ "Big Six",
            club == "Chelsea FC" ~ "Big Six",
            club == "Liverpool FC" ~ "Big Six",
            club == "Manchester City" ~ "Big Six",
            club == "Manchester United" ~ "Big Six",
            club == "Tottenham Hotspur" ~ "Big Six",
            TRUE ~ "Rest of Premier League"
        )
    )
    
transfer_history <- transfer_history %>%
    group_by(club, season) %>%
    summarise(expenditure = sum(fee, na.rm = TRUE)) %>%
    mutate(expenditure = expenditure / 1000000)

# Calculate percent difference in group expenditures
percentage_differences <- list()
i <- 1
for (year in 2010:2019) {
    df <- transfer_history %>% filter(season == year)
    percentage_differences[[i]] <- (df$expenditure[[1]] - df$expenditure[[2]]) /
        ((df$expenditure[[1]] + df$expenditure[[2]]) / 2) * 100
    i <- i + 1
}
percentage_differences <- unlist(percentage_differences)

# Colors and fonts for graphics
colors <- c("#36003C", "#00FF87")
font_add_google("Open Sans", "Open Sans")
showtext_auto()

# Visualizations
viz <- transfer_history %>%
    ggplot(aes(x = season), y = expenditure) +
    geom_line(aes(y = expenditure, alpha = 0.75, color = club), size = 1.5) +
    labs(
        title = "Big Six spending atop the rest of the Premier League",
        subtitle = paste("From 2010-2020, Arsenal, Chelsea, Liverpool,",
            "Manchester City, Manchester \nUnited, and Tottenham averaged",
            "16.05% more in annual transfer spending \nthan the other 14",
            "clubs in the league combined."),
        caption = "Source: Transfermarkt | @emordonez",
        x = "Season",
        y = "Total transfer expenditure (million \u00A3)"
    ) +
    guides(alpha = FALSE) +
    theme_minimal() +
    scale_color_manual(values = colors) +
    scale_x_continuous(breaks = transfer_history$season) +
    theme(
        legend.title = element_blank(),
        legend.position = c(1, 0),
        legend.justification = c(1, 0),
        plot.margin = margin(10, 10, 10, 10, "pt"),
        text = element_text(family = "Open Sans"),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(face = "plain"),
        plot.caption = element_text(face = "italic"),
        axis.title.x = element_text(margin = margin(7, 0, 0, 0, "pt")),
        axis.title.y = element_text(margin = margin(0, 7, 0, 0, "pt"))
    )
viz
