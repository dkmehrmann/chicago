
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)

shinyUI(
  fluidPage(
    titlePanel("Age Distribution of Chicago Communities"),
    
    h4("Minimum Viable Product Version - Andrew Mehrmann"),
    
    
    # Create a new Row in the UI for selectInputs
    fluidRow(
      column(8,
             uiOutput('cas1')
      )
    ),
    # Create a new row for the table.
    fluidRow(
      plotOutput({'plot'}, width='800px'),
      h4("Unfortunately I do not have the breakdowns by neighborhod. 
I encourage you to check out https://en.wikipedia.org/wiki/Community_areas_in_Chicago 
for more information about which neighborhoods are included in which community area.")
     )
  )
)
