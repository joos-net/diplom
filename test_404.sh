#!/bin/bash
for i in $(seq $1); do
    curl https://jo-os.ru/404 > /dev/null
done