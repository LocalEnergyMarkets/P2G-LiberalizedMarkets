############################################
### SESAM Master thesis -- Plotting tool ###
############################################

# Authors: Bobby Xiong, Johannes Predel
# (C) 2020

#######################
### Input settings ####
#######################

session <- "2020-03-25__13-46-58_old_winter_week1"

#############
### SETUP ###
#############

### Libraries
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggpubr)
library(extrafont)


### Directory
session_dir <- paste("output/", session, "/", sep = "")
if (!dir.exists(paste(session_dir, "plots", sep = ""))) dir.create(paste(session_dir, "plots", sep = ""))


### Fuel settings
# Fuel factor levels
fuel_levels <- c("Wind onshore", "Wind offshore", "Solar PV", "Oil", "NaturalGas", "Nuclear",  "Lignite", 
               "HardCoal")
fuel_levels_ext <- c("Wind onshore", "Wind offshore", "Solar PV", "Oil", "SNG", "PtG", "NaturalGas", 
                     "Nuclear", "Lignite", "HardCoal")

# Fuel colors
fcolors_data <- read.csv(file = "assets/fuelcolors.csv") 
fcolors <- fcolors_data$color %>% as.character()
names(fcolors) <- fcolors_data$fuel

# Fuel names
flabels <- fcolors_data$label %>% as.character()
names(flabels) <- fcolors_data$fuel


### Font (LaTeX)
font_import("assets", prompt = FALSE)
loadfonts(device = "win")


######################
### DATA WRANGLING ###
######################

### Economic dispatch
# Load
data_load <- read.csv(file = paste(session_dir, "load.csv", sep = ""))

# Must-run power
data_pmin <- read.csv(file = paste(session_dir, "pmin.csv", sep = ""))
data_pmin_grouped <- data_pmin %>%
  group_by(time, fuel) %>%
  summarise(output = sum(output))

# Max RES
data_maxres <- read.csv(file = paste(session_dir, "MaxRES.csv", sep = ""))
data_maxres_grouped <- data_maxres %>%
  group_by(time, fuel) %>%
  summarise(output = sum(output))

# Data for CM + PtG mechanism
data_pmin_maxres <- rbind(data_pmin_grouped, data_maxres_grouped)
data_pmin_maxres$fuel <- factor(data_pmin_maxres$fuel, levels = fuel_levels)

# Generation output of dispatchable power plants
ED_P <- read.csv(file = paste(session_dir, "ED_P.csv", sep = ""))

# Generation output of renewable energy units
ED_P_R <- read.csv(file = paste(session_dir, "ED_P_R.csv", sep = ""))

# Total dispatch 
ED_dispatch <- rbind(ED_P, ED_P_R) %>%
  group_by(time, fuel) %>%
  summarise(output = sum(output))

ED_dispatch$fuel <- factor(ED_dispatch$fuel, levels = fuel_levels)


### Congestion management
# Upward and downward adjustment of dispatchable power plants
CM_P_up <- read.csv(file = paste(session_dir, "CM_P_up.csv", sep = ""))
CM_P_dn <- read.csv(file = paste(session_dir, "CM_P_dn.csv", sep = ""))

# Upward and downward adjustment of renewable energy units
CM_P_R_up <- read.csv(file = paste(session_dir, "CM_P_R_up.csv", sep = ""))
CM_P_R_dn <- read.csv(file = paste(session_dir, "CM_P_R_dn.csv", sep = ""))

# Total redispatch
CM_redispatch <- rbind(CM_P_up, CM_P_dn, CM_P_R_up, CM_P_R_dn) %>%
  group_by(time, fuel) %>%
  summarise(output = sum(output))

CM_redispatch$fuel <- factor(CM_redispatch$fuel, levels = fuel_levels)

### Congestion management + PtG
CM_PtG_P_up <- read.csv(file = paste(session_dir, "CM_PtG_P_up.csv", sep = ""))
CM_PtG_P_dn <- read.csv(file = paste(session_dir, "CM_PtG_P_dn.csv", sep = ""))

# Upward and downward adjustment of renewable energy units
CM_PtG_P_R_up <- read.csv(file = paste(session_dir, "CM_PtG_P_R_up.csv", sep = ""))
CM_PtG_P_R_dn <- read.csv(file = paste(session_dir, "CM_PtG_P_R_dn.csv", sep = ""))

# PtG demand and SNG usage
CM_PtG_P_syn <- read.csv(file = paste(session_dir, "CM_PtG_P_syn.csv", sep = ""))
CM_PtG_D_PtG <- read.csv(file = paste(session_dir, "CM_PtG_D_PtG.csv", sep = ""))
CM_PtG_D_PtG$output <- -1*CM_PtG_D_PtG$output

# Grouped PtG demand
CM_PtG_D_PtG_grouped <- CM_PtG_D_PtG %>%
  group_by(time, fuel) %>%
  summarise(output = -1*sum(output))

# PtG storage level
CM_PtG_L_syn <- read.csv(file = paste(session_dir, "CM_PtG_L_syn.csv", sep = ""))

# Total redispatch
CM_PtG_redispatch <- rbind(CM_PtG_P_up, CM_PtG_P_dn, CM_PtG_P_R_up, CM_PtG_P_R_dn, CM_PtG_P_syn,
                           CM_PtG_D_PtG) %>%
  group_by(time, fuel) %>%
  summarise(output = sum(output))

CM_PtG_redispatch$fuel <- factor(CM_PtG_redispatch$fuel, levels = fuel_levels_ext)


### Market clearing price
ED_price <- read.csv(file = paste(session_dir, "ED_price.csv", sep = ""))

#############
### PLOTS ###
#############

loadfonts(device = "win")

### Settings
# Legend parameters
plot_legend <- theme(legend.position="bottom",
                     legend.box.margin=margin(-8,-8,-8,-8),
                     legend.key.size = unit(0.6,"line"))

# Theme parameters
plot_theme <- theme_linedraw() +
  theme(panel.border = element_rect(colour = "black", fill = NA, size = 0.2)) +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) +
  theme(axis.ticks = element_line(colour = "black", size = 0.2)) +
  theme(text = element_text(face  = "bold", size = 8, family = "NimbusRomNo9L"))

# Width of the plot in cm
plot_width <- 12.7
plot_width_png <- 20

# Display every n-th step on the x axis
plot_x_step <- 12

# Line width
plot_linesize = 0.3

# Economic dispatch
ggplot(ED_dispatch, aes(x = time, y = output, fill = fuel)) + 
  geom_area(position = "stack") + 
  plot_theme +
  scale_fill_manual(values = fcolors, name = "", labels = flabels) +
  plot_legend +
  xlab("Hour (h)") + 
  ylab("Dispatch (MW)") +
  scale_x_continuous(expand = c(0, 0), breaks = seq(0, last(ED_dispatch$time), by = plot_x_step)) +
  scale_y_continuous(expand = c(0, 0))

ggsave(filename = paste(session_dir, "plots/", "plot_economic_dispatch.pdf", sep = ""), 
       plot = last_plot(), device = "pdf", width = plot_width, height = 5.5, units = "cm", dpi = 150)

ggsave(filename = paste(session_dir, "plots/", "plot_economic_dispatch.png", sep = ""), 
       plot = last_plot(), device = "png", width = plot_width_png, height = 5.5, units = "cm", dpi = 150)

# Congestion management
ggplot(filter(CM_redispatch), aes(x = time, y = output, fill = fuel)) + 
  geom_bar(stat = "identity", position = "stack", width = 1) + 
  geom_hline(yintercept = 0, size = 0.15) + 
  plot_theme +
  scale_fill_manual(values = fcolors, name = "", labels = flabels) +
  plot_legend +
  xlab("Hour (h)") + 
  ylab("Redispatch (MW)") +
  scale_x_continuous(expand = c(0, 0), breaks = seq(0, last(CM_redispatch$time), by = plot_x_step)) +
  scale_y_continuous(expand = c(0, 0))

ggsave(filename = paste(session_dir, "plots/", "plot_redispatch.pdf", sep = ""), 
       plot = last_plot(), device = "pdf", width = plot_width, height = 5.5, units = "cm", dpi = 150)

ggsave(filename = paste(session_dir, "plots/", "plot_redispatch.png", sep = ""), 
       plot = last_plot(), device = "png", width = plot_width_png, height = 5.5, units = "cm", dpi = 150)

# Congestion management + PtG
ggplot(filter(CM_PtG_redispatch), aes(x = time, y = output, fill = fuel)) + 
  geom_bar(stat = "identity", position = "stack", width = 1) + 
  geom_hline(yintercept = 0, size = 0.15) + 
  plot_theme +
  scale_fill_manual(values = fcolors, name = "", labels = flabels) + 
  plot_legend + 
  xlab("Hour (h)") + 
  ylab("Redispatch (MW)") +
  scale_x_continuous(expand = c(0, 0), breaks = seq(0, last(CM_PtG_redispatch$time), by = plot_x_step)) +
  scale_y_continuous(expand = c(0, 0))

ggsave(filename = paste(session_dir, "plots/", "plot_redispatch_ptg.pdf", sep = ""), 
       plot = last_plot(), device = "pdf", width = plot_width, height = 5.5, units = "cm", dpi = 150)

ggsave(filename = paste(session_dir, "plots/", "plot_redispatch_ptg.png", sep = ""), 
       plot = last_plot(), device = "png", width = plot_width_png, height = 5.5, units = "cm", dpi = 150)

# Market clearing price
p_mcp <- ggplot(ED_price, aes(x = time, y = price)) + 
  geom_line(size = plot_linesize) + 
  plot_theme +
  xlab("Hour (h)") + 
  ylab("MCP (€/MWh)") +
  scale_x_continuous(expand = c(0, 0), breaks = seq(0, last(ED_price$time), by = plot_x_step)) +
  scale_y_continuous(expand = c(0, 0))

# CM + PtG mechanisms
# scale_ptg <- max(data_load$load)/max(CM_PtG_D_PtG_grouped$output)
scale_ptg <- 10

p_mech_ptg <- ggplot(data_pmin_maxres, aes(x = time, y = output)) + 
  geom_area(position = "stack", aes(fill = fuel)) + 
  geom_point(data = CM_PtG_D_PtG_grouped[which(CM_PtG_D_PtG_grouped$output>0),], aes(x = time, y = scale_ptg *output), color = fcolors["SNG"], size = 0.4, stroke = plot_linesize) + 
  geom_segment(data = CM_PtG_D_PtG_grouped[which(CM_PtG_D_PtG_grouped$output>0),], aes(x = time, xend = time, y = 0, yend = scale_ptg *output), color = fcolors["SNG"], size = plot_linesize) +
  geom_line(data = data_load, aes(x = time, y = load), size = plot_linesize) +
  plot_theme +
  scale_fill_manual(values = fcolors, name = "", labels = flabels) +
  plot_legend +
  xlab("Hour (h)") + 
  ylab("Dispatch (MW)") +
  scale_x_continuous(expand = c(0, 0), breaks = seq(0, last(data_pmin_maxres$time), by = plot_x_step)) +
  scale_y_continuous(expand = c(0, 0), sec.axis = sec_axis(~./scale_ptg , name = "PtG (MW)"))
  

# PtG storage level
p_ptg_storage <- ggplot(CM_PtG_L_syn, aes(x = time, y = storage)) + 
  geom_line(size = plot_linesize) + 
  plot_theme +
  xlab("Hour (h)") + 
  ylab(expression("SNG (MWh"["th"]*")")) +
  scale_x_continuous(expand = c(0, 0), breaks = seq(0, last(ED_price$time), by = plot_x_step)) +
  scale_y_continuous(expand = c(0, 0))

p_mech_full <- ggarrange(p_mcp, p_mech_ptg, p_ptg_storage,
          ncol = 1, nrow = 3, align = "v",
          heights = c(6, 10, 5))

ggsave(filename = paste(session_dir, "plots/", "plot_mechanism_ptg.pdf", sep = ""), 
       plot = last_plot(), device = "pdf", width = plot_width, height = 9, units = "cm", dpi = 150)

ggsave(filename = paste(session_dir, "plots/", "plot_mechanism_ptg.png", sep = ""), 
       plot = last_plot(), device = "png", width = plot_width_png, height = 9, units = "cm", dpi = 150)

# Redispatch displacement

# Redispatch colors
redisp_colors_data <- read.csv(file = "assets/redisp_colors.csv") 
redisp_colors <- redisp_colors_data$color %>% as.character()
names(redisp_colors) <- redisp_colors_data$displacement

redisp_levels <- c("Power plants down", "PtG demand", "RE curtailment", "SNG electricity", "Power plants up")

data_redisp_displacement <- data.frame(model = character(),
                                       displacement = character(),
                                       volume = double(),
                                       stringsAsFactors = FALSE)

# CM
data_redisp_displacement[1, ] <- list("CM", "PtG demand", 0)
data_redisp_displacement[2, ] <- list("CM", "Power plants down", sum(CM_P_dn$output)/1e3)
data_redisp_displacement[3, ] <- list("CM", "RE curtailment", sum(CM_P_R_dn$output)/1e3)
data_redisp_displacement[4, ] <- list("CM", "Power plants up", sum(CM_P_up$output)/1e3)
data_redisp_displacement[5, ] <- list("CM", "SNG electricity", 0)

# CM + PtG
data_redisp_displacement[6, ] <- list("CM + PtG", "PtG demand", sum(CM_PtG_D_PtG$output)/1e3)
data_redisp_displacement[7, ] <- list("CM + PtG", "Power plants down", sum(CM_PtG_P_dn$output)/1e3)
data_redisp_displacement[8, ] <- list("CM + PtG", "RE curtailment", sum(CM_PtG_P_R_dn$output)/1e3)
data_redisp_displacement[9, ] <- list("CM + PtG", "Power plants up", sum(CM_PtG_P_up$output)/1e3)
data_redisp_displacement[10, ] <- list("CM + PtG", "SNG electricity", sum(CM_PtG_P_syn$output)/1e3)

data_redisp_displacement$displacement <- factor(data_redisp_displacement$displacement, levels = redisp_levels)

ggplot(data_redisp_displacement, aes(x = model, y = volume, fill = displacement)) +
  geom_bar(stat="identity") + coord_flip() +
  plot_theme +
  scale_fill_manual(values = redisp_colors, name = "") +
  plot_legend +
  xlab("Model") + 
  ylab("Volume (GWh)") +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  guides(fill=guide_legend(nrow = 3,byrow = TRUE))

ggsave(filename = paste(session_dir, "plots/", "plot_redispatch_volume.pdf", sep = ""), 
       plot = last_plot(), device = "pdf", width = plot_width, height = 4, units = "cm", dpi = 150)

ggsave(filename = paste(session_dir, "plots/", "plot_redispatch_volume.png", sep = ""), 
       plot = last_plot(), device = "png", width = plot_width_png, height = 4, units = "cm", dpi = 150)