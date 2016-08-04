
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
# 
# http://www.rstudio.com/shiny/
#

library(shiny)
library(ggplot2)

shinyServer(function(input, output) {
  
  nms <- sort(names(ca_names))
  output$cas1 <- renderUI({
    checkboxGroupInput("ca_boxes", 
                       "Click the Boxes to Choose Neighborhoods to Compare", 
                       c(nms,"US Avg."),
                       inline=T,
                       selected='US Avg.')
  })
  
  output$plot <- renderPlot({
    df <- subset(tot, NAME %in% input$ca_boxes)
    
    ggplot(df, aes(x=variable, y=value, fill=NAME)) + 
      geom_bar(stat='identity', position='dodge') + 
      scale_fill_discrete(labels=sort(input$ca_boxes)) + 
      scale_x_discrete(labels=better_labels)+
      labs(x='Age Group', y='Density')+
      theme(axis.text.x = element_text(angle=45, hjust=1, size=12),
            axis.text.y=element_text(size=12),
            axis.title.x = element_text(size=16),
            axis.title.y=element_text(size=16),
            legend.text=element_text(size=12))
  })
  
})
