#! /usr/bin/bash
make clear
make isolate
sudo ./isolate --cleanup
sudo ./isolate --init
