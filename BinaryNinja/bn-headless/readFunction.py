import sys
import os
import requests
import time
binaryninja_api_path = "/bin/binaryninja/python/"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand
from binaryninja import SymbolType, Symbol

#stuff goes here
if len(sys.argv) < 2:
	print("bad args\n")
	sys.exit(0)

bv = binaryninja.BinaryViewType.get_view_of_file(sys.argv[1])

nmap ={}
for f in bv.functions:
    print("\nFunction " + f.name + " " + str(f.start))
    nmap[f.name] = f.start
