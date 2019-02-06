import sys
import os
import time
import hashlib
binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand, InstructionTextTokenType
#chal =  "ConsoleApplication1-Virtual.bndb"
#chal = "ConsoleApplication1-RTTI.bndb"
chal = sys.argv[1]
lib = sys.argv[2]
#print "Analyzing {0}".format(chal)
bv = binaryninja.BinaryViewType.get_view_of_file(chal)
bv.update_analysis_and_wait()

def isInstruction(instruction):
    return (instruction.type == InstructionTextTokenType.InstructionToken)
    
def isJump(instruction):
    res = False
    if instruction != False and str(instruction).startswith("j"):
        res = True
    return res

def getAssemblyString(b):
    f = b.function
    code = ""
    for i in f.instructions:
        ins = i[0]
        addr = i[1]
        last = 0l
        line = ""
        instruction = False
        for ii in ins:
            if instruction is False and isInstruction(ii):
                instruction = ii
            if not str(ii).isspace():
                #print("Type = '"+ str(ii.type) + "'" + str(ii))
                if ii.type ==  InstructionTextTokenType.PossibleAddressToken:
                    last = ii
                else:
                    line += " "
                    line += str(ii)
        line += "\n"
        if b.start <= addr and b.end > addr and not isJump(instruction):
            code += line
    #print(code)
    return code
dir="functions"
path1 = os.path.abspath(".") +"/" + dir #os.path.dirname(bv.file.filename)
if not os.path.isdir(path1):
    os.mkdir(path1)
path1 += "/" + lib + "/"
if not os.path.isdir(path1):
    os.mkdir(path1)

hash_file = open(path1+"hash.txt", "w")
for f in bv.functions:
    #if(f.name == "__onexit") and len(f.basic_blocks ) > 1:
    if len(f.basic_blocks ) > 1:
        #print(f.name)
        filename =  path1+ "/" + f.name + ".dot"
        #print(filename)
        f1 = open(filename, "w")

        f1.write("digraph{\n")
        f1.write("node [shape=record];\n")
        functionHash = ""
        for block in f.basic_blocks:
            d = block.dominator_tree_children
            m = hashlib.md5()
            ass = getAssemblyString(block)
            m.update(ass)
            #print("\"{0:x}\"[label=\"{0:x}-{1:x}-->{2}\"] ".format(block.start,block.end,str(m.hexdigest())))
            hashDigest = str(m.hexdigest())
            functionHash += hashDigest
            #print("0x{0:x}->{1:s}".format(block.start, hashDigest))
            f1.write("\"0x{0:x}\"[label=\"0x{0:x}| {3:s}| {2:s}\"] ".format(block.start, block.end, hashDigest, ass))
            
            for dom in d:
                if dom.start != block.start:
                    f1.write("\"0x{0:x}\" -> \"0x{1:x}\"".format(block.start, dom.start))
        hasher = hashlib.md5()
        hasher.update(functionHash)
        hash_file.write("{1:s}={0:s}\n".format(f.name, str(hasher.hexdigest())))            
        f1.write("}")
        f1.close()
hash_file.close()