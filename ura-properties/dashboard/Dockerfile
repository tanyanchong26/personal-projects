FROM openanalytics/r-base

LABEL maintainer "tanyanchong91@gmail.com"

# system libraries of general use

RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
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
    # for SQL
    unixodbc \
    git

# Install Basic Shiny Functionality
RUN R -e "install.packages(c('shiny'))"

# Install Other Dependencies
RUN R -e "install.packages(c('tidyverse', 'lubridate', 'dbplyr', 'jsonlite', 'sf',\
'shinythemes', 'shinydashboard', 'shinyWidgets', \
'odbc', 'DBI', \
'leaflet', 'leaflet.extras', 'plotly'))"

# Git Clone

RUN git clone https://tanyanchong:${GITHUB_TOKEN}@github.com/tanyanchong26/personal-projects.git

# Install ODBC Drivers

COPY snowflake-odbc-2.25.2.x86_64.deb /
RUN dpkg -i snowflake-odbc-2.25.2.x86_64.deb

# Copy odbcinst.ini File

COPY odbcinst.ini /etc

# Copy Environment Variables

COPY .Renviron /root

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/personal-projects/ura-properties/dashboard/', port=3838, host = '0.0.0.0')"]


