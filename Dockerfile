# Set --build-arg SRC_FORMAT=clear|obfuscated during docker build.
ARG SRC_FORMAT=obfuscated

# Stage 1 base image
FROM python:3.7-stretch AS base
LABEL project="django-react"
LABEL version="1.0.0"
LABEL author="Manoj Kumar Maharana"
LABEL author_email="mmaharana14@gmail.com"

RUN apt-get update
RUN apt-get -y install \
  postgresql \
  postgresql-contrib \
  gcc \
  python3-dev \
  musl-dev \
  netcat
# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
# App setup
WORKDIR /usr/src/app


# Stage 2 clear code
FROM base AS clear-code
COPY . .


# Stage 3 obfuscated-code
FROM base AS obfuscated-code
COPY . .
RUN pip install cython && pip install nuitka==0.6.3
RUN ./code_obfuscation.py
RUN rm code_obfuscation.py


# Stage 4 as we cannot reference build arg in COPY --from. Hence creating an intermediate image
FROM ${SRC_FORMAT}-code AS copy-src


# Stage 5 final image
FROM base AS final
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN mkdir -p new-app
COPY --from=copy-src /usr/src/app/ ./new-app/
ENTRYPOINT ["./entrypoint.sh"]
# CMD tail -f /dev/null
