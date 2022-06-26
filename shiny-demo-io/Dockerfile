FROM openanalytics/r-base

LABEL maintainer "tanyanchong91@gmail.com"

# system libraries of general use

RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxml2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    default-jdk \
    libgdal-dev \
    git
    
# Install Basic Shiny Functionality
RUN R -e "install.packages(c('shiny'))"

# Install Other Dependencies
RUN R -e "install.packages(c('shinydashboard', 'shinyWidgets', \
'shinythemes', 'DT', 'timetk', 'tidyverse', 'quantmod', \
'plotly', 'leaflet', 'httr', 'jsonlite', 'glue', \
'htmltools', 'ggthemes'))"

# Git Clone

RUN git clone https://tanyanchong:${GITHUB_TOKEN}@github.com/tanyanchong26/personal-projects.git

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/personal-projects/shiny-demo-io/', port=3838, host = '0.0.0.0')"]
