#!/bin/bash - 
#=============================================================
curl --verbose -X POST \
-H "X-Foo-Id: demo" \
-H "X-Foo-Key: jH4y7Ka81JQ8jaDc891jka9D8k3DlkM1ja8D-Zo1jwS" \
-H "Content-Type: application/json" \
--noproxy \* http://localhost/read/dataObject
