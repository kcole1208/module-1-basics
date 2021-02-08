# create sample and assignment data ####

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# dependencies ####

library(dplyr)
library(ggplot2)
library(mapview)
library(measurements)
library(sf)
library(tidycensus)
library(viridis)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# load data ####
## California
cali <- get_decennial(geography = "county", state = "CA", variables = "P001001",  
                      year = 2010, geometry = TRUE)

## Missouri
mo_total <- get_decennial(geography = "county", state = "MO", variables = "P003001",  
                          year = 2010, geometry = TRUE) 
mo_black <- get_decennial(geography = "county", state = "MO", variables = "P003003",  
                          year = 2010, geometry = FALSE) 

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# reproject
cali <- st_transform(cali, crs = 3310)
mo_total <- st_transform(mo_total, crs = 26915)

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# prep data ###
## California
cali %>%
  select(-variable) %>%
  rename(total_pop = value) %>%
  mutate(sq_km = st_area(geometry)) %>%
  mutate(sq_km = as.numeric(conv_unit(x = sq_km, from = "m2", to = "km2"))) %>%
  mutate(pop_den = total_pop/sq_km) %>%
  select(GEOID, NAME, total_pop, sq_km, pop_den, geometry) -> cali

## Missouri
### total population
mo_total %>%
  select(-variable) %>%
  rename(total_pop = value) %>%
  mutate(sq_km = st_area(geometry)) %>%
  mutate(sq_km = as.numeric(conv_unit(x = sq_km, from = "m2", to = "km2"))) %>%
  mutate(pop_den = total_pop/sq_km) %>%
  select(GEOID, NAME, total_pop, sq_km, pop_den, geometry) -> mo_total
  
### african american population
mo_black %>%
  select(-variable, -NAME) %>%
  rename(black_pop = value) -> mo_black

left_join(mo_total, mo_black, by = "GEOID") %>%
  mutate(black_den = black_pop/sq_km) %>%
  mutate(black_pct = black_pop/total_pop*100) %>%
  mutate(black_rt = black_pop/total_pop*1000) %>%
  select(GEOID, NAME, total_pop, sq_km, pop_den, black_pop, black_den, black_pct, black_rt, geometry) -> mo

rm(mo_total, mo_black)
  
#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# write data ####

st_write(cali, "data/CA_DEMOS_Total_Population/CA_DEMOS_Total_Population.shp")
st_write(mo, "data/CA_DEMOS_Total_Population/CA_DEMOS_Total_Population.geojson")

#===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===# #===#

# make maps for CA ####

## total population
p1 <- ggplot() +
  geom_sf(data = cali, mapping = aes(fill = total_pop)) +
  scale_fill_viridis(name = "Total Population") +
  labs(
    title = "Total Population by California County",
    subtitle = "2010 U.S. Census",
    caption = "Data via the U.S. Census Bureau \n Map by Christopher Prener, PhD"
  )

ggsave(plot = p1, filename = "results/california_total_population.png")

## population density
p2 <- ggplot() +
  geom_sf(data = cali, mapping = aes(fill = pop_den)) +
  scale_fill_viridis(name = "Density per \nSquare Kilometer") +
  labs(
    title = "Total Population by California County",
    subtitle = "2010 U.S. Census",
    caption = "Data via the U.S. Census Bureau \n Map by Christopher Prener, PhD"
  )

ggsave(plot = p2, filename = "results/california_population_density.png")
