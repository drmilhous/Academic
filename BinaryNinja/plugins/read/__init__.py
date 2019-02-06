import sys
import os
import hashlib
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand

def do_nothing(bv,function):
    path1 = os.path.dirname(bv.file.filename)
    d = path1 + "/functions/"
    if not os.path.isdir(d):
        os.mkdir(d)
    print(function)
    fmap = {}
    for f in bv.functions:
        fmap[f.start] = f.name
    for f in bv.functions:
        name ="Function Name " + f.name
        f1 = open(d+f.name + ".txt","w")
        #print(f)
        first = True
        f1.write("{0} @ ({1})\n".format(name,f.start ))
        for i in f.instructions:
            ins = i[0]
            addr = i[1]
            #f1.write(str(addr))
            code = ""
            last = 0l
            for ii in ins:
                if not str(ii).isspace():
                    code += " "
                    code += str(ii)
                    if str(ii.type) ==  "InstructionTextTokenType.PossibleAddressToken":
                        last = ii

            if code.startswith(" call"):
                #code += "--->"
                code = ""
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

            f1.write(code)
            f1.write("\n")
        f1.close()
        
#        for block in f.low_level_il:
#            print(dir(block))
#            for instr in block:
#                if first:
#                    f1.write("{0:s}: {1:x}\n".format(name,instr.address))

#                    first = False
                #print instr.address, instr.instr_index, instr
                # {0:x} {1:d}  instr.address, instr.instr_index, 
#                f1.write("{0:s}\n".format(instr))
		#print("END")
#        f1.close()
	#show_message_box("Do Something", "Congratulations! You have successfully done nothing.\n\n" +
	#				 "Pat yourself on the Rump.", MessageBoxButtonSet.OKButtonSet, MessageBoxIcon.ErrorIcon)
    
PluginCommand.register_for_address("Function Writer", "Writes Function Data", do_nothing)
