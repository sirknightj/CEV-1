#!/bin/sh

# Mini helper script to upload exported files to attu
# (~/web is a symlink to the CSE web home folder)
tar -czvf cev1.tar.gz export/
scp cev1.tar.gz froast@attu.cs.washington.edu:~/web
ssh froast@attu.cs.washington.edu "cd web; rm -rf cev1; tar -xvzf cev1.tar.gz; mv export cev1; rm cev1.tar.gz; exit"
