FROM google/dart-runtime
COPY ./lib/ /app/bin/
COPY ./test/test.yaml /app/bin/test.yaml
COPY ./test/files /app/bin/files
COPY ./test/common /app/bin/common
COPY ./test/test.dart /app/bin/server.dart