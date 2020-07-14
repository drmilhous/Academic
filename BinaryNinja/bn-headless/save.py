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
chal =  sys.argv[1]
bv = binaryninja.BinaryViewType["ELF"].open(chal)
bv.update_analysis_and_wait()
bv.create_database("fred.bndb")

bv = binaryninja.BinaryViewType.get_view_of_file("fred.bndb")

nmap ={}
for f in bv.functions:
    print("\nFunction " + f.name + " " + str(f.start))
    nmap[f.name] = f.start
a = raw_input("Enter current function name:")
b = raw_input("Enter new function name:")
address = nmap[a]
symbol_type = SymbolType.FunctionSymbol
symbol = b
bv.define_user_symbol(Symbol(symbol_type, address, symbol))
print("{0:s}->{1:s} {2:x}".format(a,b,address))
bv.save_auto_snapshot()
