#!/bin/bash

for piece in {10000..11737}
#for piece in {11736..11736}
do
 echo "kicking off $piece"
 qsubstata.sh soundexmatchalltitlespieces $piece
done

