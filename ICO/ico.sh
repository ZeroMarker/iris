curl -X POST http://iris:52773/api/coffeeco/inventory/getbeans/1/2.4 | jq

curl -X POST -d "@product_brazil_dark.json" \
 -H "Content-Type: application/json" \
 http://iris:52773/api/coffeeco/catalog/catalogproduct