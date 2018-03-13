import sys
import os
import time
import hashlib
binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand
chal =  "ConsoleApplication1-Virtual.bndb"
print "Analyzing {0}".format(chal)
bv = binaryninja.BinaryViewType.get_view_of_file(chal)
bv.update_analysis_and_wait()
def getAssemblyString(b):
    f = b.function
    code = ""
    for i in f.instructions:
        ins = i[0]
        addr = i[1]
        last = 0l
        line = ""
        for ii in ins:
            if not str(ii).isspace():
                line += " "
                line += str(ii)
                if str(ii.type) ==  "InstructionTextTokenType.PossibleAddressToken":
                    last = ii
        line += "\n"
        if b.start <= addr and b.end > addr:
            code += line
    return code
dir="dot"
for f in bv.functions:
    if(f.name == "__ftol2") or True:
        print(f.name)
        path1 = os.path.dirname("/Users/mattmiller/Academic/BinaryNinja/")+"/" + dir + "/"#os.path.dirname(bv.file.filename)
        if not os.path.isdir(path1):
            os.mkdir(path1)
        filename =  path1+ "/" + f.name + ".dot"
        print(filename)
        f1 = open(filename, "w")
        f1.write("digraph{\n")
        f1.write("node [shape=record];\n")
        for block in f.basic_blocks:
            d = block.dominator_tree_children
            m = hashlib.md5()
            ass = getAssemblyString(block)
            m.update(ass)
            #print("\"{0:x}\"[label=\"{0:x}-{1:x}-->{2}\"] ".format(block.start,block.end,str(m.hexdigest())))
            f1.write("\"0x{0:x}\"[label=\"0x{0:x}| {3:s}| {2:s}\"] ".format(block.start, block.end, str(m.hexdigest()),ass))
            for dom in d:
                if dom.start != block.start:
                    f1.write("\"0x{0:x}\" -> \"0x{1:x}\"".format(block.start, dom.start))
                    
        f1.write("}")
        f1.close()
