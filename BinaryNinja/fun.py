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
    
for f in bv.functions:
    if(f.name == "__ftol2"):
        print(f.name)
        p = str(os.path.dirname(bv.file.filename))
        filename =  p + "/" + f.name + ".dot"
        print(filename)
        f1 = open(filename, "w")
        f1.write("digraph{")
        for block in f.basic_blocks:
    #        print(str(block) + "----->>>")
            d = block.dominators
            #for block1 in f.basic_blocks:
            #    if block1 != block:
            m = hashlib.md5()
            ass = getAssemblyString(block)
            m.update(ass)
            #print("\"{0:x}\"[label=\"{0:x}-{1:x}-->{2}\"] ".format(block.start,block.end,str(m.hexdigest())))
            f1.write("\"{0:x}\"[label=\"{0:x}-{1:x}\"] ".format(block.start, block.end, str(m.hexdigest())))
    #        print(d)
            for dom in d:
                ok = True
                dom2 = "hi"
                for b1 in f.basic_blocks:
                    if b1.start == dom.start:
                        dom2 = b1.dominators

                for dd in dom2:
                    #print("{0} -> {1}".format(dd.start,b1.start))
                    if dd.start == block.start:
                        ok = False
                #print("dom->" + str(dom))
                #print("dom2->" + str(dom2))
                if dom.start != block.start and ok == True :
                    f1.write("\"{0:x}\" -> \"{1:x}\"".format(dom.start,block.start))
                #print(x.get_disassembly_text())
                #help(x)
                #exit()
        f1.write("}")
        f1.close()
