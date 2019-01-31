aws apigateway update-integration-response \
--rest-api-id 744dkxdz6e \
--resource-id g9pgui \
--http-method GET \
--status-code 200 \
--patch-operations '[{"op" : "replace", "path" : "/contentHandling", "value" : "CONVERT_TO_BINARY"}]'