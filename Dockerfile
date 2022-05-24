FROM google/dart-runtime
COPY ./lib/ /app/bin/
COPY ./test/test.yaml /app/bin/test.yaml
#COPY ./test/external/ /app/bin/src/
COPY ./test/test.dart /app/bin/server.dart