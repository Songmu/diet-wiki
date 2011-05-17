#!/bin/sh
cd $(dirname $0)
cd ..
script/publish.pl
git ci -am "atom.xml"
git push
dotcloud push songmu.dietcolumn .

