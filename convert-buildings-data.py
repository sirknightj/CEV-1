#!/usr/bin/env python3

"""
Converts the buildings.csv file downloaded from Google Sheets into a JSON file readable by Haxe.
"""
import csv
import json

BUILDINGS_CSV_PATH = "assets/data/buildings.csv"
BUILDINGS_JSON_PATH = "assets/data/buildings.json"


def convert(d):
	res = {}
	for k, v in d.items():
		new = k.lower().replace(" ", "_")
		if 'cost' in new or 'effect' in new:
			v = int(v or 0)
		elif new == 'shape':
			shape = v.split('\n')
			width = max(len(s) for s in shape)
			v = [[x == '#' for x in s.ljust(width, ' ')] for s in shape]
		res[new] = v
	return res


with open(BUILDINGS_CSV_PATH) as csvfile:
	reader = csv.DictReader(csvfile)
	res = [convert(row) for row in reader]
	with open(BUILDINGS_JSON_PATH, 'w') as jsonfile:
		json.dump(res, jsonfile)
