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
    libgdal-dev
    
# Install Basic Shiny Functionality
RUN R -e "install.packages(c('shiny'))"

# Install Other Dependencies
RUN R -e "install.packages(c('shinydashboard', 'shinyWidgets', \
'shinythemes', 'DT', 'tidyverse', 'rjson', 'magrittr', \
'plotly', 'httr', 'jsonlite', 'glue', \
'slider', 'tidymodels', 'DT'))"

# copy the app and file dependencies to the image

RUN mkdir /root/crypto-coingecko
COPY global.R /root/crypto-coingecko
COPY server.R /root/crypto-coingecko
COPY ui.R /root/crypto-coingecko
COPY Rprofile.site /usr/lib/R/etc/

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/root/crypto-coingecko', port=3838, host = '0.0.0.0')"]


