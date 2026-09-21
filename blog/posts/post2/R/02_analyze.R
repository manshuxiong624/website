suppressPackageStartupMessages({
  library(dplyr); library(readr); library(stringr); library(ggplot2)
})
budget <- 1500 # Illustrative monthly BASE-rent budget, not an all-in-cost ceiling.
dir.create('figures', showWarnings=FALSE)
raw <- read_csv('data/floorplans_raw.csv', show_col_types=FALSE)

# Do not coerce 'Call for Availability' to zero, or average an area range.
get_numbers <- function(x) str_extract_all(str_remove_all(x, ','), '[0-9]+(?:\\.[0-9]+)?')
rent_numbers <- get_numbers(raw$rent_raw)
size_numbers <- get_numbers(raw$sqft_raw)
first_number <- function(x) if(length(x)) as.numeric(x[1]) else NA_real_
last_number <- function(x) if(length(x)) as.numeric(tail(x,1)) else NA_real_
clean <- raw %>% mutate(
  beds = if_else(str_detect(str_to_lower(beds_raw), 'studio'), 0, suppressWarnings(as.numeric(beds_raw))),
  baths = suppressWarnings(as.numeric(baths_raw)),
  rent_start = vapply(rent_numbers, first_number, numeric(1)),
  sqft_min = vapply(size_numbers, first_number, numeric(1)),
  sqft_max = vapply(size_numbers, last_number, numeric(1)),
  exact_area = lengths(size_numbers) == 1L,
  special_layout = str_detect(str_to_lower(model_raw), 'jr|junior|den|bi.level|town'),
  area = case_when(
    str_detect(location_heading, regex('Roxborough',ignore_case=TRUE)) ~ 'Roxborough',
    str_detect(location_heading, regex('Manayunk',ignore_case=TRUE)) ~ 'Manayunk',
    str_detect(location_heading, regex('Mt\\.?\\s*Airy|Mount Airy',ignore_case=TRUE)) ~ 'Mount Airy',
    str_detect(location_heading, regex('Wynnefield',ignore_case=TRUE)) ~ 'Wynnefield',
    str_detect(location_heading, regex('Fox Chase|Somerton|Bustleton|Rhawnhurst|Northeast',ignore_case=TRUE)) ~ 'Northeast Philadelphia',
    TRUE ~ NA_character_),
  eligible_standard_1br = beds == 1 & baths == 1 & !special_layout,
  exclusion_reason = case_when(
    beds != 1 ~ 'Not one bedroom',
    baths != 1 ~ 'Not one bathroom',
    special_layout ~ 'Junior, den, bi-level or townhouse layout',
    is.na(rent_start) ~ 'No published numerical rent',
    TRUE ~ 'Included'),
  monthly_rent_per_sqft = if_else(exact_area & !is.na(rent_start), rent_start/sqft_min, NA_real_),
  within_base_budget = !is.na(rent_start) & rent_start <= budget)
if(anyNA(clean$area)) stop('Unmapped location headings: ', paste(unique(clean$location_heading[is.na(clean$area)]),collapse='; '))
if(any(clean$rent_start <= 0,na.rm=TRUE) || any(clean$sqft_min <= 0,na.rm=TRUE)) stop('Nonpositive rent or size: inspect data.')
if(any(clean$sqft_min > clean$sqft_max,na.rm=TRUE)) stop('Area range is reversed.')
write_csv(clean,'data/floorplans_clean.csv')
one <- filter(clean, eligible_standard_1br, !is.na(rent_start))
if(anyDuplicated(one$slug)) stop('Multiple standard one-bedroom models at one property: review weighting before comparing areas.')
write_csv(one,'data/one_bedroom_comparison.csv')
summary <- one %>% group_by(area) %>% summarise(
  properties_with_published_rent=n(), median_starting_rent=median(rent_start),
  minimum_starting_rent=min(rent_start), maximum_starting_rent=max(rent_start),
  properties_at_or_below_budget=sum(within_base_budget),
  share_at_or_below_budget=mean(within_base_budget), .groups='drop') %>% arrange(median_starting_rent)
write_csv(summary,'data/area_summary.csv')
audit <- clean %>% count(exclusion_reason,name='floorplan_rows')
write_csv(audit,'data/exclusions.csv')

colors <- c('Roxborough'='#16766d','Mount Airy'='#bc682f','Northeast Philadelphia'='#516eaa','Wynnefield'='#84669c','Manayunk'='#747b45')
base_theme <- theme_minimal(base_size=12,base_family='sans') + theme(
  plot.title=element_text(face='bold',size=19), plot.subtitle=element_text(size=11,color='#4e5c64'),
  panel.grid.minor=element_blank(), panel.grid.major.y=element_blank(),
  plot.caption=element_text(hjust=0,size=9,color='#57636a'), legend.position='bottom',
  plot.margin=margin(15,25,15,15),plot.background=element_rect(fill='white',color=NA))
plot_data <- one %>% arrange(rent_start) %>% mutate(property=factor(property,levels=property))
p1 <- ggplot(plot_data,aes(rent_start,property,color=area)) +
  geom_vline(xintercept=budget,linetype='dashed',color='#b8493c',linewidth=.7) +
  geom_segment(aes(x=0,xend=rent_start,yend=property),linewidth=.8,alpha=.3) +
  geom_point(size=3) + geom_text(aes(label=scales::dollar(rent_start,accuracy=1)),hjust=-.25,size=3.3,show.legend=FALSE) +
  scale_color_manual(values=colors) + scale_x_continuous(labels=scales::label_dollar(),limits=c(0,max(one$rent_start)*1.17),expand=expansion(mult=c(0,.02))) +
  labs(title='Which Philadelphia properties fit a $1,500 base-rent budget?',
    subtitle='Published starting monthly rents for standard one-bedroom, one-bathroom layouts',
    x='Starting base rent (USD / month)',y=NULL,color=NULL,
    caption='Dashed line: $1,500. Galman Group pages, collected September 21, 2026.\nOne observation per property; advertised floor plans, not counts of vacant apartments. Fees and availability vary.') + base_theme
# The dates below follow the collected snapshot and change automatically on a refresh.
collection_date <- substr(min(one$retrieved_at_utc),1,10)
p1 <- p1 + labs(caption=paste0('Dashed line: $1,500. Galman Group pages, collected ',collection_date,'.\nOne observation per property; advertised floor plans, not counts of vacant apartments. Fees and availability vary.'))
ggsave('figures/starting_rents.png',p1,width=10.8,height=max(6.5,.32*nrow(one)+2.5),dpi=180,bg='white')

exact <- one %>% filter(exact_area) %>% arrange(monthly_rent_per_sqft) %>% mutate(property=factor(property,levels=property))
p2 <- ggplot(exact,aes(monthly_rent_per_sqft,property,color=area)) +
  geom_point(size=3) + geom_text(aes(label=sprintf('$%.2f',monthly_rent_per_sqft)),hjust=-.3,size=3.3,show.legend=FALSE) +
  scale_color_manual(values=colors) + scale_x_continuous(labels=scales::label_dollar(),limits=c(0,max(exact$monthly_rent_per_sqft)*1.2)) +
  labs(title='A lower rent does not always mean more space per dollar',
    subtitle='Starting rent divided by the single floor-plan area reported on the page',
    x='Starting base rent per square foot (USD / month)',y=NULL,color=NULL,
    caption=paste0('Source: Galman Group, ',collection_date,'. Area ranges excluded; these are advertised ratios, not unit-specific quotes.')) + base_theme
ggsave('figures/rent_per_sqft.png',p2,width=10.8,height=max(6.5,.32*nrow(exact)+2.5),dpi=180,bg='white')
writeLines(capture.output(sessionInfo()),'data/sessionInfo.txt')
print(summary)
print(select(one,property,area,rent_start,sqft_raw,monthly_rent_per_sqft),n=40)
