import sys
import os
import time
import requests
import hashlib
binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand
from binaryninja import SymbolType, Symbol
chal =  "ConsoleApplication1-Virtual.bndb"
print "Analyzing {0}".format(chal)
bv = binaryninja.BinaryViewType.get_view_of_file(chal)
bv.update_analysis_and_wait()
badnames = ""
bn = []
nmap ={}
for f in bv.functions:
    badnames+=f.name + "\n"
    bn.append(f.name)
    nmap[f.name] = f.start
x = {"input":badnames}
r = requests.post("https://demangler.com/raw", data=x)  
index = 0
lines = r.text.split("\n")
for l in lines:
    if (index < len(bn)-1):
        name = bn[index]
        if l != name:
            #print("  {0:s}\n->{1:s}".format(l,bn[index]))
            address = nmap[name]
            symbol_type = SymbolType.FunctionSymbol
            symbol = l
            bv.define_user_symbol(Symbol(symbol_type, address, symbol))
    index += 1
bv.save_auto_snapshot()