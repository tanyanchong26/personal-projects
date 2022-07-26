FROM openanalytics/r-base

LABEL maintainer "tanyanchong91@gmail.com"

# system libraries of general use

RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    build-essential \
    # tidyverse
    libcairo2-dev \
    libxml2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    # java
    default-jdk \
    # for Leaflet
    libgdal-dev \
    # sf package dependency
    libudunits2-dev \
    libgeos-dev \
    libproj-dev \
    git

# Install Basic Shiny Functionality
RUN R -e "install.packages(c('shiny'))"
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/terra/terra_1.5-34.tar.gz', repos=NULL, type='source')"

# Install Other Dependencies
RUN R -e "install.packages(c('tidyverse', 'lubridate', 'jsonlite', 'sf',\
'shinythemes', 'shinydashboard', 'shinyWidgets', \
'leaflet', 'leaflet.extras', 'plotly'))"

# Git Clone

RUN git clone https://tanyanchong:${GITHUB_TOKEN}@github.com/tanyanchong26/personal-projects.git

# Copy Data Files

COPY polygons.csv /personal-projects/ura-properties/csv-dashboard/
COPY transactions.csv /personal-projects/ura-properties/csv-dashboard/

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/personal-projects/ura-properties/csv-dashboard/', port=3838, host = '0.0.0.0')"]


