FROM google/dart-runtime
COPY ./lib/ /app/bin/
COPY ./test/test.dart /app/bin/server.dart