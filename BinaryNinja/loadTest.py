import sys
import os
import time
binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand
bv = binaryninja.BinaryViewType.open("ConsoleApplication1-Virtual.bndb")
print y
bv = binaryninja.BinaryViewType["PE"].open("ConsoleApplication1-Virtual.exe")
bv.update_analysis_and_wait()
ctx = PluginCommandContext(bv)
ctx = PluginCommandContext(bv)
y = PluginCommand.get_valid_list(ctx)['Load PDB (BETA)']
y.execute(ctx)
#for p in PluginCommand.get_valid_list(ctx):
#    print(p)
#    if p == 'Load PDB (BETA)' :
#        p.execute(ctx)
#x = PluginCommand.get_valid_list(ctx)
#PluginCommand.get_valid_list(ctx)['Load PDB (BETA)'].execute(ctx) 
#print(x)
#x[0].execute(ctx)
#x = PluginCommand.get_valid_list(ctx)['Load PDB (BETA)'].execute(ctx) 