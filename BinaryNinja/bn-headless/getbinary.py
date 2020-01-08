import sys
import os
import requests
import time
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand

#stuff goes here
if len(sys.argv) < 3:
	print("Arg 1 input binary\nArg2 output file")
	sys.exit(0)

chal =  sys.argv[1]
##chal ="/bin/ls"
bv = binaryninja.BinaryViewType["ELF"].open(chal)

bv.update_analysis_and_wait()
for f in bv.functions:
    if not  f.name.startswith("sub_"): 
        print("Function " + f.name + " " + str(f.start))
theFun = input("Enter the Function Name: ").strip()
text = ""
count = 0
name = sys.argv[2]
binFile = open(name, "wb")
for f in bv.functions:
    if f.name == theFun:
        print("\nFunction " + f.name + " " + str(f.start))
        for i in f.instructions:
            ins = i[0]
            addr = i[1]
            code = ""
            lenI = bv.get_instruction_length(addr)
            instructionBytes = bv.read(addr,lenI)
            binFile.write(instructionBytes)
            bytesText = ""
            padding = 0
            for x in list(instructionBytes):
                bytesText = bytesText + " {0:02x}".format(x)
                padding = padding + 1
                text = text + "{0:02x}".format(x)
                count = count  +1
                if count % 16 == 0:
                    count = 0
                    text = text + "\n"
            for i in range(padding, 8):
                bytesText = bytesText + "   "
            #text = text + bytesText
            #code = "Len " + str(lenI) + " -> " + bytesText
            code = bytesText
            # + "{0:x}".format(text)
            for ii in ins:
                if not str(ii).isspace():
                    code += " "
                    code += str(ii)
            print(code)
binFile.close()
print("writing " + name + "\t Data\n")
#f = open(name , "w")
#f.write(text)
print(text)
#f.close()