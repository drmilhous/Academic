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

chal = "./ConsoleApplication1-RTTI.bndb"
bv = binaryninja.BinaryViewType.get_view_of_file(chal)
bv.update_analysis_and_wait()

max = 0
for f in bv.functions:
    count = 0
    for i in f.instructions:
        addr = i[1]
        len = bv.get_instruction_length(addr)
        print(addr)
        x = addr
        while x <= addr+len:
            curr = bv.read(x, 1).encode('hex')
            print(curr),
            x = x+ 1
            count = count + 1
        print("")
    if count > max:
        max = count
print("The mamimum is " + str(max))


#if not os.path.exists(directory):
#    os.makedirs(directory)
#f1b1 = f1.basic_blocks[0]
#addr = f1b1.start
#y = bv.perform_read(addr,3)
#print(y)

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
from binaryninja import *
bv = BinaryViewType['Mach-O'].open("/bin/ls")
br = BinaryReader(bv)
hex(br.read32())
