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
    default-jdk
    
# Install Basic Shiny Functionality
RUN R -e "install.packages(c('shiny'))"

# Install Other Dependencies
RUN R -e "install.packages(c('shinydashboard', 'shinyWidgets', \
'shinythemes', 'DT', 'aws.s3'))"

# copy the app and file dependencies to the image

RUN mkdir /root/shiny-demo
COPY global.R /root/shiny-demo
COPY server.R /root/shiny-demo
COPY ui.R /root/shiny-demo
COPY DESCRIPTION /root/shiny-demo
COPY README.md /root/shiny-demo
COPY .Renviron /root
COPY Rprofile.site /usr/lib/R/etc/

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/root/shiny-demo', port=3838, host = '0.0.0.0')"]


