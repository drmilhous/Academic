import sys
import os
import requests
import time
binaryninja_api_path = "/bin/binaryninja/python/"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand

#stuff goes here
if len(sys.argv) < 2:
	print("bad args\n")
	sys.exit(0)
chal =  sys.argv[1]
bv = binaryninja.BinaryViewType["ELF"].open(chal)
bv.update_analysis_and_wait()
for f in bv.functions:
	print("\nFunction " + f.name + " " + str(f.start))
	for i in f.instructions:
		ins = i[0]
		addr = i[1]
		code = ""
		for ii in ins:
			if not str(ii).isspace():
				code += " "
				code += str(ii)
		print(code)
