# library(dplyr)
library(tidyverse)
library(readr)
library(ggplot2)
library(janitor)
library(RColorBrewer)

setwd("C:/Users/joepo/Documents/Uni/UCL CASA/CASA0011/assessment1")

ss2 <- read_csv('output/Sugarscape 2 Constant Growback_custom test-wealth-dist-by-endowment-table.csv', skip = 6)

ss3 <- read_csv('output/Sugarscape 3 Wealth Distribution_custom test-wealth-dist-by-vision-table.csv', skip = 6)

ss2_curve <- read_csv('output/Sugarscape 2 Constant Growback_custom mean-sugar-by-max-endowment-1000-table.csv', skip = 6) %>%
  clean_names()

ss3_curve <- read_csv('output/Sugarscape 3 Wealth Distribution_custom mean-sugar-by-max-endowment-table.csv', skip = 6) %>%
  clean_names()

ss3_ginicurve <- read_csv("output/Sugarscape 3 Wealth Distribution_custom gini-by-max-endowment-1000-table.csv", skip = 6) %>%
  clean_names()

ss2_ginicurve <- read_csv("output/Sugarscape 2 Constant Growback_custom gini-by-max-endowment-1000-table.csv", skip=6) %>%
  clean_names()


# 0. Set formatting values ------------------------------------------------

output_style <- "wide"
# output_style <- "square"

if (output_style == "wide") {
  filepath <- "output/"
  figure_width <- 20
  figure_height <- 8
  legend_pos <- "right"
} else {
  filepath <- "output/squarefigs/"
  figure_width <- 12
  figure_height <- 12
  legend_pos <- "bottom"
}


# 1. Plot SS2 Means --------------------------------------------

ss2_cln <- ss2 %>%
  mutate(endowclass = case_when(`maximum-sugar-endowment` == 25 ~ "Low - 25",
                                `maximum-sugar-endowment` == 50 ~ "Med - 50",
                                `maximum-sugar-endowment` == 100 ~ "High - 100",
                                `maximum-sugar-endowment` == 1000 ~ "Extreme - 1000")) %>%
  select(-visualization, -`initial-population`, -`[step]`) 
  
# ss2_grp <- ss2_cln %>%
#   group_by(`maximum-sugar-endowment`, `minimum-sugar-endowment`) %>%
#   summarise(count_turtles = mean(`count turtles`),
#             mean_sugar = mean(`mean-sugar`),
#             mean_lowviz = mean(`mean-lowviz`),
#             mean_hiviz = mean(`mean-hiviz`),
#             mean_lowmtb = mean(`mean-lowmtb`)
#   )
# 
# 
# ss2_grp2 <- ss2_grp %>%
#   group_by(`maximum-sugar-endowment`) %>%
#   summarise(count_turtles = mean(count_turtles),
#             mean_sugar = mean(mean_sugar),
#             mean_lowviz = mean(mean_lowviz),
#             mean_hiviz = mean(mean_hiviz),
#             mean_lowmtb = mean(mean_lowmtb)
#             ) 

#Low viz to High viz plotting comparisons
ss2_plt_means <- ss2_cln %>%
  select(`endowclass`, `mean-sugar`, `mean-lowviz`, `mean-hiviz`, `mean-lowmtb`, `mean-himtb`) %>%
  pivot_longer(cols = c(`mean-sugar`:`mean-himtb`), 
               names_to = "population", names_prefix = "mean-",
               values_to = "value") %>%
  mutate(population = case_when(population == "sugar" ~ "Total",
                                population == "lowviz" ~ "Low vision",
                                population == "hiviz" ~ "High vision",
                                population == "lowmtb" ~ "Low metabolism",
                                population == "himtb" ~ "High metabolism")) %>%
  mutate(value = na_if(value, 0))

# Plot

plt <- ggplot(ss2_plt_means, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100", "Extreme - 1000")), 
                                y = value, fill = factor(population, level=c("Total", "Low vision", "High vision", "Low metabolism", "High metabolism")))) +
  geom_boxplot() +
  ylim(0, 1500) +
  labs(x = "\nMaximum Endowment", y = "Mean sugar\n", fill = NULL, tag = "(a)") +
  theme_classic() +
  theme(legend.position=legend_pos)
plt


ggsave(paste0(filepath, "ss2_fig1_mean-sugar-by-max-endowment.png"),
       width = figure_width, height = figure_height, units = "cm")



# 1.2 Plot SS2 Means by EndowMin ------------------------------------------

ss2_meansbymin <- ss2_cln %>%
  clean_names() %>%
  mutate(endowclass_min = factor(minimum_sugar_endowment, level=c("0", "5", "10", "15", "20")))

# Plot
plt <- ggplot(ss2_meansbymin, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100", "Extreme - 1000")), 
                            y = mean_sugar, fill = endowclass_min)) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Mean Sugar\n", fill = "Min. endowment", tag = "(a)") +
  theme_classic() +
  scale_fill_brewer(palette="PuBu") +
  theme(legend.position=legend_pos)
plt

ggsave(paste0(filepath, "ss2_fig1c_mean-sugar-by-maxmin-endowment.png"),
       width = figure_width, height = figure_height, units = "cm")




# 2. Plot SS3 Means -------------------------------------------------------

ss3_cln <- ss3 %>%
  mutate(endowclass = case_when(`maximum-sugar-endowment` == 25 ~ "Low - 25",
                                `maximum-sugar-endowment` == 50 ~ "Med - 50",
                                `maximum-sugar-endowment` == 100 ~ "High - 100",
                                `maximum-sugar-endowment` == 1000 ~ "Extreme - 1000")) %>%
  select(-visualization, -`initial-population`, -`[step]`) 


#Low viz to High viz plotting comparisons
ss3_plt_means <- ss3_cln %>%
  select(`endowclass`, `mean-sugar`, `mean-lowviz`, `mean-hiviz`, `mean-lowmtb`, `mean-himtb`) %>%
  pivot_longer(cols = c(`mean-sugar`:`mean-himtb`), 
               names_to = "population", names_prefix = "mean-",
               values_to = "value") %>%
  mutate(population = case_when(population == "sugar" ~ "Total",
                                population == "lowviz" ~ "Low vision",
                                population == "hiviz" ~ "High vision",
                                population == "lowmtb" ~ "Low metabolism",
                                population == "himtb" ~ "High metabolism"))

# Plot
plt <- ggplot(ss3_plt_means, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100", "Extreme - 1000")), 
                                 y = value, fill = factor(population, level=c("Low vision", "High vision", "Low metabolism", "High metabolism", "Total")))) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Mean sugar\n", fill = NULL) +
  theme_classic() +
  # scale_fill_brewer(palette="Dark2") +
  theme(legend.position=legend_pos)
plt

ggsave(paste0(filepath, "ss3_fig1_mean-sugar-by-max-endowment.png"),
       width = figure_width, height = figure_height, units = "cm")



# Plot without Extreme
ss3b_plt_means <- ss3_plt_means %>%
  filter(endowclass != "Extreme - 1000")

plt <- ggplot(ss3b_plt_means, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100")), 
                                 y = value, fill = factor(population, level=c("Total", "Low vision", "High vision", "Low metabolism", "High metabolism")))) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Mean sugar\n", fill = NULL, tag = "(b)") +
  theme_classic() +
  # scale_fill_brewer(palette="Pastel1") +
  theme(legend.position=legend_pos)

plt

ggsave(paste0(filepath, "ss3_fig1b_mean-sugar-by-max-endowment.png"),
       width = figure_width, height = figure_height, units = "cm")


# 2.2 Plot SS3 Means by EndowMin ------------------------------------------

ss3_meansbymin <- ss3_cln %>%
  clean_names() %>%
  mutate(endowclass_min = factor(minimum_sugar_endowment, level=c("0", "5", "10", "15", "20")))

# Plot
plt <- ggplot(ss3_meansbymin, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100", "Extreme - 1000")), 
                                  y = mean_sugar, fill = endowclass_min)) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Mean Sugar\n", fill = "Min. endowment", tag = "(b)") +
  theme_classic() +
  scale_fill_brewer(palette="PuRd") +
  theme(legend.position=legend_pos)
plt

ggsave(paste0(filepath, "ss3_fig1d_mean-sugar-by-maxmin-endowment-withextreme.png"),
       width = figure_width, height = figure_height, units = "cm")


#Plot without extreme
ss3_meansbymin <- ss3_cln %>%
  clean_names() %>%
  mutate(endowclass_min = factor(minimum_sugar_endowment, level=c("0", "5", "10", "15", "20"))) %>%
  filter(maximum_sugar_endowment != 1000)

# Plot
plt <- ggplot(ss3_meansbymin, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100")), 
                                  y = mean_sugar, fill = endowclass_min)) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Mean Sugar\n", fill = "Min. endowment", tag = "(b)") +
  theme_classic() +
  scale_fill_brewer(palette="PuRd") +
  theme(legend.position=legend_pos)
plt

ggsave(paste0(filepath, "ss3_fig1d_mean-sugar-by-maxmin-endowment.png"),
       width = figure_width, height = figure_height, units = "cm")



# 3. Plot Gini values -----------------------------------------------------

#SS2
ss2_gini <- ss2 %>%
  select(`maximum-sugar-endowment`, `minimum-sugar-endowment`, `gini-index-reserve`,
         `count turtles`) %>%
  clean_names() %>%
  mutate(gini_index = (gini_index_reserve/count_turtles)*2,
         endowclass = case_when(maximum_sugar_endowment == 25 ~ "Low - 25",
                                maximum_sugar_endowment == 50 ~ "Med - 50",
                                maximum_sugar_endowment == 100 ~ "High - 100",
                                maximum_sugar_endowment == 1000 ~ "Extreme - 1000"),
         endowclass_min = factor(minimum_sugar_endowment, level=c("0", "5", "10", "15", "20"))
  )

# Plot

plt <- ggplot(ss2_gini, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100", "Extreme - 1000")), 
                            y = gini_index, fill = endowclass_min)) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Gini index\n", fill = "Min. endowment", tag = "(a)") +
  theme_classic() +
  scale_fill_brewer(palette="PuBu") +
  theme(legend.position=legend_pos)

ggsave(paste0(filepath, "ss2_fig2_gini-index-by-max-endowment.png"),
       width = figure_width, height = figure_height, units = "cm")

plt

#SS3
ss3_gini <- ss3 %>%
  select(`maximum-sugar-endowment`, `minimum-sugar-endowment`, `gini-index-reserve`,
         `starve-count`, `age-death-count`) %>%
  clean_names() %>%
  mutate(gini_index = (gini_index_reserve/400)*2,
         endowclass = case_when(maximum_sugar_endowment == 25 ~ "Low - 25",
                                maximum_sugar_endowment == 50 ~ "Med - 50",
                                maximum_sugar_endowment == 100 ~ "High - 100",
                                maximum_sugar_endowment == 1000 ~ "Extreme - 1000"),
         endowclass_min = factor(minimum_sugar_endowment, level=c("0", "5", "10", "15", "20"))
         )

# Plot

plt <- ggplot(ss3_gini, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100", "Extreme - 1000")), 
                                y = gini_index, fill = endowclass_min)) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Gini index\n", fill = "Min. endowment", tag = "(b)") +
  theme_classic() +
  scale_fill_brewer(palette="PuRd") +
  theme(legend.position=legend_pos)

ggsave(paste0(filepath, "ss3_fig2_gini-index-by-max-endowment.png"),
       width = figure_width, height = figure_height, units = "cm")

plt

# # ScatterPlot
# plt2 <- ggplot(ss3_gini, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100", "Extreme - 1000")), 
#                              y = gini_index, col = endowclass_min)) +
#   geom_jitter() +
#   labs(x = "\nMaximum Endowment", y = "Gini index\n", col = "Minimum \nendowment") +
#   theme_classic() +
#   scale_color_brewer(palette="PuRd")
# 
# plt2



# 4. Starve Ratio ----------------------------------------------------------

ss3_sr <- ss3_gini %>%
  mutate(starve_ratio = starve_count/(starve_count + age_death_count))

#Plot
plt <- ggplot(ss3_sr, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100", "Extreme - 1000")), 
                            y = starve_ratio, fill = endowclass_min)) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Starve Ratio\n", fill = "Min. endowment") +
  theme_classic() +
  scale_fill_brewer(palette="Reds") +
  theme(legend.position=legend_pos)
plt

ggsave(paste0(filepath, "ss3_fig3_starve-ratio-by-max-endowment-withextreme.png"),
       width = figure_width, height = figure_height, units = "cm")


#Plot without extreme
ss3_srb <- ss3_sr %>%
  filter(maximum_sugar_endowment != 1000)

plt <- ggplot(ss3_srb, aes(x = factor(endowclass, level=c("Low - 25", "Med - 50", "High - 100")), 
                          y = starve_ratio, fill = endowclass_min)) +
  geom_boxplot() +
  labs(x = "\nMaximum Endowment", y = "Starve Ratio\n", fill = "Min. endowment") +
  theme_classic() +
  scale_fill_brewer(palette="Reds") +
  theme(legend.position=legend_pos)

plt

ggsave(paste0(filepath, "ss3_fig3b_starve-ratio-by-max-endowment.png"),
       width = figure_width, height = figure_height, units = "cm")



# 5. Run statistical tests for significance ----------------------------------------

# 5.1 Test difference in the mean sugar across classes of maximum endowment 

#Create columns to test
ss2_himtb_extreme <- ss2_cln %>% 
  filter(endowclass == "Extreme - 1000") %>%
  pull(`mean-himtb`)

ss2_total_extreme <- ss2_cln %>% 
  pull(`mean-himtb`)

t.test(ss2_himtb_extreme, ss2_total_extreme, var.equal=TRUE)

#Try ANOVA
ss2_aov <- aov(value ~ population, 
               data = filter(ss2_plt_means, endowclass == "Extreme - 1000"))
summary(ss2_aov)

ss2_aov2 <- aov(value ~ population, 
                data = filter(ss2_plt_means, endowclass == "Low - 25"))
summary(ss2_aov2)


# 5.2 Linear models for association between max endowment and mean sugar

#SS2
ss2_lm <- lm(mean_sugar ~ maximum_sugar_endowment, data = ss2_curve)
summary(ss2_lm)

#SS3
ss3_lm <- lm(mean_sugar ~ maximum_sugar_endowment, data = ss3_curve)
summary(ss3_lm)

# 6. Plot curves ----------------------------------------------------------

#SS3
plt <- ggplot(ss3_curve, aes(x = maximum_sugar_endowment, y = mean_sugar, col = sd_sugar)) +
  geom_jitter() +
  ylim(0, 1000) +
  labs(x = "\nMaximum Endowment", y = "Mean Sugar\n", col = "Std. dev.", tag = "(b)") +
  theme_classic() + 
  scale_color_distiller(palette="Reds") +
  theme(legend.position=legend_pos)
plt
ggsave(paste0(filepath, "ss3_curve_1000.png"), width = figure_width, height = figure_height, units = "cm")

#SS2
plt <- ggplot(ss2_curve, aes(x = maximum_sugar_endowment, y = mean_sugar, col = sd_sugar)) +
  geom_jitter() +
  ylim(0, 1000) +
  # geom_smooth(method = "lm", col = "blue") +
  labs(x = "\nMaximum Endowment", y = "Mean Sugar\n", col = "Std. dev.", tag = "(a)") +
  theme_classic() +
  theme(legend.position=legend_pos)
plt
ggsave(paste0(filepath, "ss2_curve_1000.png"), width = figure_width, height = figure_height, units = "cm")



# 6.1 Gini Index Curves to 1000 -------------------------------------------

# SS3 Gini Index 

ss3_gini2 <- ss3_ginicurve %>%
  mutate(gini_index = (gini_index_reserve/400)*2)

plt <- ggplot(ss3_gini2, aes(x = maximum_sugar_endowment, y = gini_index, col = mean_sugar)) +
  geom_jitter() +
  ylim(0.15, 0.45) +
  labs(x = "\nMaximum Endowment", y = "Gini Index\n", col = "Mean sugar", tag = "(b)") +
  theme_classic() +
  scale_color_distiller(palette="Reds") +
  theme(legend.position=legend_pos)
plt
ggsave(paste0(filepath, "ss3_curve_gini.png"), width = figure_width, height = figure_height, units = "cm")


# SS2 Gini Index
ss2_gini2 <- ss2_ginicurve %>%
  mutate(gini_index = (gini_index_reserve/400)*2)

plt <- ggplot(ss2_gini2, aes(x = maximum_sugar_endowment, y = gini_index, col = mean_sugar)) +
  geom_jitter() +
  ylim(0.15, 0.45) +
  labs(x = "\nMaximum Endowment", y = "Gini Index\n", col = "Mean sugar", tag = "(a)") +
  theme_classic() +
  scale_color_distiller(palette="Blues") +
  theme(legend.position=legend_pos)
plt
ggsave(paste0(filepath, "ss2_curve_gini.png"), width = figure_width, height = figure_height, units = "cm")
