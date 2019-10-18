import sys
import os
import requests
import time
binaryninja_api_path = "/bin/binaryninja/python/"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand

def traverse_IL(il, indent):
  if isinstance(il, LowLevelILInstruction):
    print('\t'*indent + il.operation.name)
 
    for o in il.operands:
      traverse_IL(o, indent+1)
 
  else:
    print('\t'*indent + str(il))


#stuff goes here
if len(sys.argv) < 2:
	print("bad args\n")
	sys.exit(0)
chal =  sys.argv[1]
bv = binaryninja.BinaryViewType["ELF"].open(chal)
bv.update_analysis_and_wait()
for f in bv.functions:
    print("\nFunction " + f.name)
    for i in f.lifted_il:
	for ins in i.disassembly_text:
		print(ins)
	#help(i)
	#sys.exit(0)

