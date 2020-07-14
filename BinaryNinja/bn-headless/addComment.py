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
	print("Enter database as argument\n")
	sys.exit(0)

bv = binaryninja.BinaryViewType.get_view_of_file(sys.argv[1])

for f in bv.functions:
    print("\nFunction " + f.name + " " + str(f.start))

a = raw_input("Enter current function name:")
b = raw_input("Enter the comment:")
for f in bv.functions:
	if f.name == a:
		f.set_comment_at(f.start, b)



bv.save_auto_snapshot()
