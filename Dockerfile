# Stage 0
FROM node:12.13 AS node

# Set working directory
WORKDIR /app

# Install node dependencies
COPY package*.json /app/
RUN npm install --silent

# Transfer application files
COPY . /app/

# Build web UI
RUN npm run build

# Stage 1
FROM python:3.8

WORKDIR /usr/src/app

# Initial image setup
RUN apt-get update && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get autoremove -y

# Ensure build fails if any command using pipes fail at any sub-command
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Julia
RUN curl -sLO "https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-0.6.4-linux-x86_64.tar.gz"
RUN tar -xvzf julia-0.6.4-linux-x86_64.tar.gz
RUN mv julia-9d11f62bcb/ julia-0.6 && rm julia-0.6.4-linux-x86_64.tar.gz

# Create julia package
RUN ./julia-0.6/bin/julia -e 'Pkg.add.(["CSV", "DataFrames", "LightGraphs", "Optim", "BinDeps"])'

# Set up python dependencies
COPY requirements.txt server.py /usr/src/app/
RUN pip install -r requirements.txt

# Transfer application files
COPY src/ /usr/src/app/src/

# Copy web UI from stage 0
COPY --from=node /app/static /usr/src/app/static

# Configure server
EXPOSE 5000
ENV FLASK_APP server.py

CMD ["flask", "run", "--host=0.0.0.0"]
