#pip install cxxfilt
#pip install requests
import sys
import os
import time
binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand
chal =  "ConsoleApplication1-Virtual.bndb"
print "Analyzing {0}".format(chal)
bv = binaryninja.BinaryViewType.get_view_of_file(chal)
bv.update_analysis_and_wait()
fmap = {}
for f in bv.functions:
    fmap[f.start] = f.name
for k, v in fmap.items():
    print(k, v)
for f in bv.functions:
    for i in f.instructions:
        ins = i[0]
        addr = i[1]
        code = ""
        last = 0l
        for ii in ins:
            if not str(ii).isspace():
                code += " "
                code += str(ii)
                if str(ii.type) ==  "InstructionTextTokenType.PossibleAddressToken":
                    last = ii
        #print(last.type)
        if code.startswith(" call"):
            code += "--->"
            for ii in ins:
                if not str(ii).isspace():
                    code += " "
                    value = str(ii)
                    if str(ii.type) ==  "InstructionTextTokenType.PossibleAddressToken":
                        last = int(str(ii), 16)
                        if last in fmap: 
                            value = fmap[last]
                        else: 
                            value = bv.get_symbol_at(last).name
                    code += value
            print(code) 
            #for ii in ins:
                #if not str(ii).isspace():
                    #help(ii)
                    #quit()