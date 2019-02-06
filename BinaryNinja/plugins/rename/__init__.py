import sys
import os
sys.path.append("/opt/local/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages/cppmangle")
import cppmangle
import requests
import time
import hashlib
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand
from binaryninja import SymbolType, Symbol

def do_nothing(bv,function):
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

PluginCommand.register_for_address("Rename C++ functions", "Renames the functions by demangling", do_nothing)
