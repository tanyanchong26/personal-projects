FROM continuumio/miniconda3

# Install pip requirements
COPY requirements.txt .
RUN python -m pip install -r requirements.txt

COPY . .

CMD gunicorn -b 0.0.0.0:80 app:server
