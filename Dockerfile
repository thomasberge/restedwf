#FROM thomasberge/dart-base:2.14.4-amd64
#FROM thomasberge/dart-base:2.17.0-amd64
FROM thomasberge/dart-base:2.18.6-amd64

WORKDIR /app

ADD pubspec.* /app/
RUN dart pub get
ADD pubspec.yaml /app/pubspec.yaml
RUN dart pub get --offline

COPY ./lib/ /app/bin/
COPY ./test/test.dart /app/bin/server.dart