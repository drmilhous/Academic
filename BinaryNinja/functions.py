import sys
import os
import time
binaryninja_api_path = "/Applications/Binary Ninja.app/Contents/Resources/python"
sys.path.append(binaryninja_api_path)
import binaryninja
from binaryninja import PluginCommandContext, PluginCommand
bv = binaryninja.BinaryViewType.get_view_of_file("ConsoleApplication1-Virtual.bndb")
