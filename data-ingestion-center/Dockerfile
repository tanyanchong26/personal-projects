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
    git
    
# Install Basic Shiny Functionality
RUN R -e "install.packages(c('shiny'))"

# Install Other Dependencies
RUN R -e "install.packages(c('shinydashboard', 'shinyWidgets', \
'shinythemes', 'DT', 'aws.s3'))"

# Git Clone

RUN git clone https://tanyanchong:${GITHUB_TOKEN}@github.com/tanyanchong26/personal-projects.git

# copy the app and file dependencies to the image

COPY .Renviron /root

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/personal-projects/data-ingestion-center/', port=3838, host = '0.0.0.0')"]


