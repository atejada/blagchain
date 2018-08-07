#!/bin/bash

cd Blagchain
crystal run src/Blagchain.cr &
sleep 1s
cd ..
cd BlagchainClient
crystal run src/BlagchainClient.cr
