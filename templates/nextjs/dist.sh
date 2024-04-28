#! /usr/bin/env bash

pnpm build
mkdir -p build/tmp
cp -r public build/tmp
cp -r .next/standalone/. build/tmp
cp -r .next/static build/tmp/.next

patch ./build/tmp/server.js << 'EOF'
--- server.js
+++ patched
@@ -1,9 +1,4 @@
-const path = require('path')
-
-const dir = path.join(__dirname)
-
 process.env.NODE_ENV = 'production'
-process.chdir(__dirname)
 
 const currentPort = parseInt(process.env.PORT, 10) || 3000
 const hostname = process.env.HOSTNAME || '0.0.0.0'
@@ -25,7 +20,7 @@
 }
 
 startServer({
-  dir,
+  dir: __dirname,
   isDev: false,
   config: nextConfig,
   hostname,
EOF

patch ./build/tmp/package.json << 'EOF'
--- package.json
+++ patched
@@ -1,1 +1,12 @@
 {
+  "bin": "server.js",
+  "pkg": {
+    "targets": [
+      "node20-linux-x64"
+    ],
+    "assets": [
+      "public/**/*",
+      ".next/**/*"
+    ],
+    "outputPath": "dist"
+  },
EOF

cd build/tmp
npx @yao-pkg/pkg .

cd ..
mv tmp/dist/* .
rm -rf tmp

