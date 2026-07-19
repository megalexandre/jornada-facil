docker build --platform linux/amd64 \
  -t alexandreqrz/fttelecom-api:v1 \
  -t alexandreqrz/fttelecom-api:latest . \
&& docker push alexandreqrz/fttelecom-api:latest
