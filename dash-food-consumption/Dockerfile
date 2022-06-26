FROM continuumio/miniconda3

RUN apt-get update && apt-get install -y \
    sudo \
    git

# Git Clone

RUN git clone https://tanyanchong:${GITHUB_TOKEN}@github.com/tanyanchong26/personal-projects.git
WORKDIR "/personal-projects/dash-food-consumption/"

# Install pip requirements
RUN python -m pip install -r requirements.txt

CMD gunicorn -b 0.0.0.0:80 app:server
