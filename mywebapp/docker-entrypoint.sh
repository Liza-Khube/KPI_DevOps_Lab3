#!/bin/sh
set -e

echo "Running migrations..."
node migration.js

echo "Starting server..."
exec node server.js