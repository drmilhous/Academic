import sys
import os
import requests
import time
platform = sys.platform
binaryninja_api_path = ""
if "darwin" in platform:
    binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
elif "linux" in platform:
    binaryninja_api_path = "/bin/binaryninja/python/"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand

#stuff goes here
if len(sys.argv) < 2:
	print("bad args\n")
	sys.exit(0)
chal =  sys.argv[1]
bv = binaryninja.BinaryViewType["ELF"].open(chal)
bv.update_analysis_and_wait()
