library(jsonlite) # used for handling the API request
library(tidyverse) # used for moving around the data within the script. 
# note that we will use PACKAGENAME::FUNCTION , or "::" notation to specify 
# the package which functions are coming from. This is not neccessary if the
# above packages are attached, but helpful for future code maintenace. 

# documentation for the Index Herbariorum API is available on github at
# https://github.com/nybgvh/IH-API/wiki
# Essentially we are going to need to make two calls. One to grab the information 
# on shipping addresses and a suitable point of contact at the herbarium, 
# the second to get the contacts name - in the general case when a contact is 
# specified 

url <- "http://sweetgum.nybg.org/science/api/v1/institutions/search?country=U.S.A."
museums <- jsonlite::fromJSON(url)$data # this will grab the data if request is 200

# we will manually list the fields we want in an external vector. We are going to 
# pass these values into dplyr::select using dplyr::all_of, if any of these field names 
# change THIS CODE WILL BREAK. It is intentional, it should be pretty easy to 
# maintain this code as required: The three fields we are specifically grabbing are:
# irn = internal record number - shouldnt actually be used and can be discarded in the future? 
# orgnization = the name of the individual herbarium 
# code = the index herbariorum code for each herbarium
# all three of the above values should be distinct, but some organizations with 
# generic names should be shared. 

museum_fields <- c('irn', 'organization', 'code')

museums <- bind_cols(
  dplyr::select(museums, dplyr::all_of(fields)), 
  
  # the flattening of the json result is a little wonky, while the returned object may 
  # look like a data frame, it's actually a list and rstdio doesn't show it's true
  # properties correctly. We can pull out data frames and info we like from them
  # by subsetting with the `$` function
  
  museums$address |>
    dplyr::select(dplyr::starts_with('postal')), # we want SHIPPING addresses, not address for visitors. 
  museums$contact
)

rm(museum_fields)


# gather some info for people, basically we want first and last names for contacts
url <- "http://sweetgum.nybg.org/science/api/v1/staff/search?country=U.S.A."
people <- jsonlite::fromJSON(url)$data

# define a look up vector again, and let's try to make sure we have the people
# designated as correspondents. 
# irn = internal record number - shouldnt actually be used and can be discarded in the future? 
# code = the index herbariorum code for each herbarium
# correspondent = a boolean field (Yes/No), is this the person we should be emailing? 

people_fields <- c('irn', 'code', 'firstName', 'lastName', 'correspondent')

people <- bind_cols(
  dplyr::select(people, dplyr::all_of(people_fields)), 
  people$contact
)

rm(people_fields, url)
