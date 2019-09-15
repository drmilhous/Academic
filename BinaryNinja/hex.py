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
    print("Arg 2: dir")
#    sys.exit(0)
    chal = "./ConsoleApplication1-RTTI.bndb"
    baseDir = "ConsoleApplication1-RTTI"
else:
    chal =  sys.argv[1]
    baseDir = sys.argv[2]

if ".bndb" in chal:
    bv = binaryninja.BinaryViewType.get_view_of_file(chal)
elif ".exe" in chal:
    bv = binaryninja.BinaryViewType["PE"].open(chal)
else:
    bv = binaryninja.BinaryViewType["ELF"].open(chal)

bv.update_analysis_and_wait()


if not os.path.exists(baseDir):
    os.makedirs(baseDir)
max = 0
for f in bv.functions:
    currDir = baseDir + "/" + f.name
    if not os.path.exists(currDir):
        os.makedirs(currDir)
    currFile = currDir + "/" + "out.txt"
    f1 = open(currFile, "w")
    count = 0
    for i in f.instructions:
        addr = i[1]
        len = bv.get_instruction_length(addr)
        print(addr)
        x = addr
        while x <= addr+len:
            curr = bv.read(x, 1).encode('hex') # hex string
            print(curr),
            f1.write(str(int(curr, 16)) + "\n" ) # convert string to decimal (0-255)
            x = x+ 1
            count = count + 1
        print("")
    f1.close()
    if count > max:
        max = count
print("The mamimum is " + str(max))
