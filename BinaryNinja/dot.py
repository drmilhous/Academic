import sys
import os
import time
import hashlib
import requests
from sets import Set
platform = sys.platform
binaryninja_api_path = ""

if "darwin" in platform:
    binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
elif "linux" in platform:
    binaryninja_api_path = "/bin/binaryninja/python/"
    
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand, InstructionTextTokenType

if len(sys.argv) < 3:
    print("Arg 1: binary or db to open\n")
    print("Arg 2: dot file to save")
    sys.exit(0)
#    chal = "./ConsoleApplication1-RTTI.bndb"
#    outfile = "bob.dot"
else:
    chal =  sys.argv[1]
    outfile = sys.argv[2]

if ".bndb" in chal:
    bv = binaryninja.BinaryViewType.get_view_of_file(chal)
else:
    bv = binaryninja.BinaryViewType["ELF"].open(chal)
    
bv.update_analysis_and_wait()


f1 = open(outfile, "w")
f1.write("digraph{\n")
f1.write("node [shape=record];\n")
s = Set()
for f in bv.functions:
    print("\n\nFunction " + f.name)
    code = ""
    for i in f.instructions:
        ins = i[0]
        addr = i[1] 
        currentInstruction = None
        for ii in ins:
            if ii.type == InstructionTextTokenType.PossibleAddressToken :
                code = "\"0x{0:x}\" -> \"{1:s}\"".format(f.start, str(ii))
            elif ii.type == InstructionTextTokenType.InstructionToken:
                currentInstruction = str(ii)
        if "call" in currentInstruction:
            f1.write(code)
        code += "\n"    
    print(code)
f1.write("}\n")
f1.close()
print(s)

 