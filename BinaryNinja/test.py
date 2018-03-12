#pip install cxxfilt
#pip install requests
import sys
import os
import requests
#import cxxfilt
import cppmangle
import time
binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand
def do_nothing(bv,function, d):
	#show_message_box("Do Something", "Congratulations! You have successfully done nothing.\n\n" +
	#				 "Pat yourself on the Rump.", MessageBoxButtonSet.OKButtonSet, MessageBoxIcon.ErrorIcon)
	#print(function)
    badnames = ""
    bn = []
    for f in bv.functions:
        try:
            x = cppmangle.cdecl_sym(cppmangle.demangle(f.name))
        except:
            #y = "??_Gexception@std@@UAEPAXI@Z"
            #x = {"input":f.name}
            #r = requests.post("https://demangler.com/raw", data=x)
            #x = r.text
            badnames+=f.name + "\n"
            bn.append(f.name)
            x=f.name
        name ="Function Name " +x #f.name #cxxfilt.demangle(f.name)
        print(name)
        if False:
            for i in f.instructions:
                ins = i[0]
                addr = i[1]
                print(addr),
                for ii in ins:
                    if not str(ii).isspace():
                        print ii,
                print 
        print
    #print(badnames)  
    x = {"input":badnames}
    r = requests.post("https://demangler.com/raw", data=x)  
    index = 0
    lines = r.text.split("\n")
    print("Lines {0:d}".format(len(lines)))
    print("BN    {0:d}".format(len(bn)))
    
    for l in lines:
        if (index < len(bn)) and l != bn[index]:
            print("  {0:s}\n->{1:s}".format(l,bn[index]))
        index += 1
    return
    for f in bv.functions:
        name ="Function Name " + f.name
        f1 = open(d+"/"+f.name + ".txt","w")
        #print(f)
        first = True
        for block in f.low_level_il:
            print(dir(block))
            for instr in block:
                if first:
                    f1.write("{0:s}: {1:x}\n".format(name,instr.address))
                    first = False
                #print instr.address, instr.instr_index, instr
                # {0:x} {1:d}  instr.address, instr.instr_index, 
                f1.write("{0:s}\n".format(instr))
		#print("END")
        f1.close()
        
        
chal =  sys.argv[1]
d = sys.argv[2]    
print "Analyzing {0}".format(chal)
bv = binaryninja.BinaryViewType.get_view_of_file(chal)
bv.update_analysis_and_wait()
#bv = binaryninja.BinaryViewType["PE"].open(chal)
#bv.update_analysis_and_wait()
#time.sleep(2) 
#ctx = PluginCommandContext(bv); next(p for p in PluginCommand.get_valid_list(ctx) if p.name  == 'Load PDB (BETA)').execute(ctx)
#ctx = PluginCommandContext(bv); PluginCommand.get_valid_list(ctx)['Load PDB (BETA)'].execute(ctx) 

#ctx = PluginCommandContext(bv) 
#for p in PluginCommand.get_valid_list(ctx):
#    if (p.name  == 'Load PDB (BETA)'):
#        p.execute(ctx)
#time.sleep(2) 
if not os.path.isdir(d):
    os.mkdir(d)
do_nothing(bv, chal,d)