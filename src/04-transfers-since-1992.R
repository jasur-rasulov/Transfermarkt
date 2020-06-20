#'
#' Obervations from transfer records of the top five European leagues,
#' 1992-2020.
#'

# DEPENDENCIES
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
    "data.table", "dplyr", "ggplot2", "Hmisc", "readr", "showtext",
    "treemap"
)
source("./src/01-clean.R")


# DATA
# Regex in case data before 1992 have already been scraped
dirs <- dir("./data", pattern = "[12][019]\\d\\d")
pl_files <- file.path("./data", dirs, paste0("premier-league.csv"))
buli_files <- file.path("./data", dirs, paste0("1-bundesliga.csv"))
laliga_files <- file.path("./data", dirs, paste0("laliga.csv"))
seriea_files <- file.path("./data", dirs, paste0("serie-a.csv"))
ligue1_files <- file.path("./data", dirs, paste0("ligue-1.csv"))

pl_data <- lapply(pl_files, read_csv)
buli_data <- lapply(buli_files, read_csv)
laliga_data <- lapply(laliga_files, read_csv)
seriea_data <- lapply(seriea_files, read_csv)
ligue1_data <- lapply(ligue1_files, read_csv)

# Clean and combine data
pl <- rbindlist(pl_data, use.names = TRUE) %>% tidy_transfers()
buli <- rbindlist(buli_data, use.names = TRUE) %>%
    tidy_transfers() %>%
    mutate(league = "Bundesliga")
laliga <- rbindlist(laliga_data, use.names = TRUE) %>%
    tidy_transfers() %>%
    mutate(league = "La Liga")
seriea <- rbindlist(seriea_data, use.names = TRUE) %>% tidy_transfers()
ligue1 <- rbindlist(ligue1_data, use.names = TRUE) %>% tidy_transfers()

transfers <- rbind(pl, buli, laliga, seriea, ligue1)


# ANALYSIS
# 04-1: Top 25 most expensive transfers since 1992
purchases <- transfers %>% filter(movement == "In" & (!is_loan | fee > 0))
biggest_purchases <- purchases %>%
    arrange(desc(fee)) %>%
    slice(1:25) %>%
    mutate(fee = fee / 1e6) %>%
    mutate(
        club = case_when(
            club == "Paris Saint-Germain" ~ "PSG",
            club == "FC Barcelona" ~ "Barcelona",
            club == "Juventus FC" ~ "Juventus",
            club == "Manchester United" ~ "Man United",
            club == "Liverpool FC" ~ "Liverpool",
            club == "Arsenal FC" ~ "Arsenal",
            club == "Chelsea FC" ~ "Chelsea",
            club == "Manchester City" ~ "Man City",
            TRUE ~ club
        )
    ) %>%
    select(name, club, fee, season) %>%
    arrange(name)

# 04-2: Most expensive transfers adjusted for inflation
# Indices for real 2019 GBP sourced from the Bank of England
# https://www.bankofengland.co.uk/monetary-policy/inflation/inflation-calculator
inflation_index <- setNames(c(
    2.09, 2.05, 2.00, 1.94, 1.89, 1.83, 1.77, 1.75, 1.70, 1.67, 1.64, 1.59,
    1.55, 1.50, 1.46, 1.40, 1.34, 1.35, 1.29, 1.23, 1.19, 1.15, 1.13, 1.12,
    1.10, 1.06, 1.03, 1.00
), as.character(1992:2019))

adj_biggest_purchases <- purchases %>%
    mutate(fee = fee * inflation_index[as.character(season)] / 1e6) %>%
    arrange(desc(fee)) %>%
    slice(1:25) %>%
    mutate(
        club = case_when(
            club == "Paris Saint-Germain" ~ "PSG",
            club == "FC Barcelona" ~ "Barcelona",
            club == "Juventus FC" ~ "Juventus",
            club == "Manchester United" ~ "Man United",
            club == "SS Lazio" ~ "Lazio",
            club == "Liverpool FC" ~ "Liverpool",
            club == "Manchester City" ~ "Man City",
            TRUE ~ club
        )
    ) %>%
    select(name, club, fee, season) %>%
    arrange(name)

# 04-3: Growth of total transfer spending in the Premier League
pl_trend <- pl %>%
    filter(movement == "In" & !is.na(fee) & fee > 0) %>%
    mutate(fee = fee * inflation_index[as.character(season)] / 1e6)

# 04-4: Premier League inflation compared to UK inflation
pl_inflation <- pl %>%
    filter(movement == "In" & !is.na(fee) & fee > 0) %>%
    group_by(season) %>%
    dplyr::summarize(mean = mean(fee), median = median(fee)) %>%
    mutate(
        mean = mean / 1e6,
        median = median / 1e6
    )

# 04-5: Treemap of total league spending since 2000
league_totals <- transfers %>%
    filter(season >= 2000) %>%
    filter(movement == "In", !is.na(fee), fee > 0) %>%
    mutate(
        club = case_when(
            # Choice of big clubs for the treemap
            # Premier League
            club == "Manchester City" |
                club == "Manchester United" ~ club,
            club == "Arsenal FC" ~ "Arsenal",
            club == "Chelsea FC" ~ "Chelsea",
            club == "Liverpool FC" ~ "Liverpool",
            club == "Tottenham Hotspur" ~ "Tottenham",
            # Bundesliga
            club == "Bayern Munich" ~ club,
            club == "Borussia Dortmund" ~ "Dortmund",
            # La Liga
            club == "Atlético Madrid" |
                club == "Real Madrid" ~ club,
            club == "FC Barcelona" ~ "Barcelona",
            club == "Valencia CF" ~ "Valencia",
            # Serie A
            club == "AC Milan" |
                club == "Milan AC" ~ "AC Milan",
            club == "AS Roma" ~ "Roma",
            club == "Inter Milan" |
                club == "FC Internazionale" ~ "Inter Milan",
            club == "Juventus FC" ~ "Juventus",
            club == "SSC Napoli" ~ "Napoli",
            # Ligue 1
            club == "AS Monaco" ~ "Monaco",
            club == "Paris Saint-Germain" ~ "PSG",
            club == "Olympique Lyon" ~ "Lyon",
            club == "Olympique Marseille" ~ "OM",
            # The rest
            TRUE ~ ""
        )
    ) %>%
    # League labeled with total expenditure, only for treemap
    group_by(league) %>%
    mutate(
        league_label = paste(
            league,
            sprintf("\u00A3%.2fb", sum(fee) / 1e9), sep = "\n"
        )
    )


# VISUALIZATIONS
# Colors and fonts
font_add_google("Open Sans", "Open Sans")
showtext_auto()

# 04-1: Top 25 most expensive transfers since 1992
x1 <- rownames(biggest_purchases)
viz_biggest_purchases <- biggest_purchases %>%
    ggplot(aes(x = reorder(x1, fee), y = fee)) +
    geom_col(fill = alpha("#00088E", 0.65)) +
    geom_text(
        aes(
            label = sprintf("\u00A3%.fm", fee),
            y = fee,
            hjust = -0.2,
            fontface = "bold"
        ),
        color = "black",
        size = 3.1
    ) +
    geom_text(
        aes(
            label = sprintf("%s, %d", club, season),
            y = 2.5,
            hjust = 0,
            fontface = "bold.italic"
        ),
        color = "white",
        size = 3.1
    ) +
    labs(
        title = "The 25 most ever expensive European transfers",
        subtitle = paste("Barcelona and Real Madrid have each paid five of the",
            "biggest ever transfer \nfees. Neymar and Ronaldo are the only",
            "players to make the list twice."),
        caption = "Source: Transfermarkt | @emordonez",
        x = NULL,
        y = NULL
    ) +
    theme_minimal() +
    scale_x_discrete(
        labels = biggest_purchases$name[order(biggest_purchases$fee)]
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    theme(
        legend.position = "none",
        plot.margin = margin(10, 10, 10, 10, "pt"),
        text = element_text(family = "Open Sans"),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(face = "plain"),
        plot.caption = element_text(face = "italic"),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()
    ) +
    coord_flip()
viz_biggest_purchases

# 4-02: Most expensive transfers adjusted for inflation
x2 <- rownames(adj_biggest_purchases)
viz_adj_biggest_purchases <- adj_biggest_purchases %>%
    ggplot(aes(x = reorder(x2, fee), y = fee)) +
    geom_col(fill = alpha("#F61225", 0.75)) +
    geom_text(
        aes(
            label = sprintf("\u00A3%.fm", fee),
            y = fee,
            hjust = -0.2,
            fontface = "bold"
        ),
        color = "black",
        size = 3.1
    ) +
    geom_text(
        aes(
            label = sprintf("%s, %d", club, season),
            y = 2.5,
            hjust = 0,
            fontface = "bold.italic"
        ),
        color = "white",
        size = 3.1
    ) +
    labs(
        title = "Biggest ever transfers adjusted for inflation",
        subtitle = paste("Zidane's world-record transfer in 2001 would be in",
            "the top five most \nexpensive transfers in 2019. All fees are in",
            "real 2019 GBP."),
        caption = "Source: Transfermarkt, Bank of England | @emordonez",
        x = NULL,
        y = NULL
    ) +
    theme_minimal() +
    scale_x_discrete(
        labels = adj_biggest_purchases$name[order(adj_biggest_purchases$fee)]
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    theme(
        legend.position = "none",
        plot.margin = margin(10, 10, 10, 10, "pt"),
        text = element_text(family = "Open Sans"),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(face = "plain"),
        plot.caption = element_text(face = "italic"),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank()
    ) +
    coord_flip()
viz_adj_biggest_purchases

# 04-3: Growth of total transfer spending in the Premier League
viz_pl_trend <- pl_trend %>%
    ggplot(aes(x = season, y = fee)) +
    geom_point(alpha = 0.25) +
    geom_smooth(
        aes(color = "Median transfer fee with IQR"),
        stat = "summary", alpha = 0.25, fill = "red",
        fun.data = median_hilow, fun.args = list(conf.int = 0.5)
    ) +
    geom_line(
        aes(color = "Mean transfer fee"),
        stat = "summary", fun = mean, size = 1
    ) +
    geom_line(
        aes(color = "Max transfer fee"),
        stat = "summary", fun = max, size = 1
    ) +
    labs(
        title = "The real growth of Premier League transfer fees",
        subtitle = paste("With over 3,000 fees paid since 1992, the typical",
            "Premier League transfer is \nbecoming more and more expensive.",
            "This growth is driven by more frequent \npurchases in the upper",
            "extreme each window."),
        caption = "Source: Transfermarkt, Bank of England | @emordonez",
        x = NULL,
        y = "Million \u00A3 (real, 2019)"
    ) +
    theme_minimal() +
    scale_color_manual(values = c("black", "blue", "red")) +
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
viz_pl_trend

# 04-4: Premier League inflation compared to UK inflation
viz_inflation <- pl_inflation %>%
    ggplot(aes(x = season)) +
    geom_line(aes(y = median, color = "Median transfer fee"), size = 1) +
    geom_line(aes(y = mean, color = "Mean transfer fee"), size = 1) +
    geom_segment(
        aes(
            x = 1992, y = median[1],
            xend = 2019, yend = 2.09 * median[1],
            color = "1992 median adjusted for average UK inflation"
        ),
        size = 1
    ) +
    labs(
        title = "Premier League inflation far outpaces UK inflation",
        subtitle = paste("Adjusted for inflation, the median transfer fee",
            "has increased by 715% and the average \nby 786% since 1992.",
            "Inflation in the UK has averaged 2.8% per year since then."),
        caption = "Source: Transfermarkt, Bank of England | @emordonez",
        x = NULL,
        y = "Million \u00A3 (real, 2019)"
    ) +
    theme_minimal() +
    scale_color_manual(values = c("black", "blue", "red")) +
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
viz_inflation

# 04-5: Treemaps of league spending since 2000
treemap(league_totals,
    index = c("league_label", "club"), vSize = "fee", type = "index",
    palette = "Set1",
    fontcolor.labels = c("white", "white"),
    align.labels = list(c("left", "top"), c("center", "center")),
    xmod.labels = c(0.1, 0),
    ymod.labels = c(-0.1, 0),
    bg.labels = 0,
    title = "Total transfer spending in Europe's top 5 leagues since 2000",
    fontfamily.title = "Open Sans",
    fontfamily.labels = "Open Sans",
    fontsize.labels = c(12, 10)
)
