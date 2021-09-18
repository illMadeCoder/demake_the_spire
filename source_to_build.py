"""
Program is built to take pico-8 source code and apply some
transformations to allow for high level constructs which are 
token intensive to be compiled into a new pico-8 source code file which 
disposes the abstraction for the sake of saving tokens.

Sections:
Read Args
 python source_to_build.py <source file> -v? (verbose mode)
Read In Source File

Includes
 Allows for #include in pico-8 code, will all be pulled into the build file
Debug Code
Enums
Enum_Function_maps
Unnecessary Tokens

Output Build File
"""

import sys
import re

#common
def vprint(_str, _indent):
    if is_verbose:
        print("\t"*_indent + _str)

def vvprint(_str, _indent):
    if is_very_verbose:
        vprint(_str, _indent)

def vvresub(_re, _replace_str, _str, _indent):
    (ret, n) = re.subn(_re, _replace_str, _str)
    re_pattern = (_re if isinstance(_re, str) else _re.pattern)
    vvprint("resub: " +
            repr(re_pattern) +
           " performed " +
           str(n) +
            " sub(s)", _indent)
    return ret
        
p8_header_re = re.compile("pico-8.*cartridge.*__lua__", re.DOTALL)
def is_valid_p8(_str):
    return re.match(p8_header_re, _str) != None

#Section: Read Args
input_file_name = sys.argv[1]
output_file_name = "build.p8"
is_very_verbose = "-vv" in sys.argv
is_verbose = "-v" in sys.argv or is_very_verbose
vprint("Section: Read Args", 0)
vprint("program args: " + str(sys.argv), 1)

#Section: Read In Source File
vprint("Section: Read in Source File", 0)
with open(input_file_name, "r+") as input_file:
    build = input_file.read()
    
if not is_valid_p8(build):
    raise Exception("Error on read in source file: " + input_file_name)
else:
    vprint("input_file_name valid", 1)    

#Section: Includes

#include strings look like <#include <file path>>
vprint("Section: Includes", 0)

for include_file_path in re.findall("#include (.*)", build):
    vprint("opening for include: " + include_file_path, 1)
    with open(include_file_path) as include_file:        
        include_str = include_file.read()
        
        if not is_valid_p8(include_str):
            raise Exception("Error on read in include file: " + include_file_path)
        
        include_body_match = re.match(".*__lua__(.*)", include_str, re.DOTALL)
        
        if include_body_match == None:
            vprint("found no body for: " + include_file_path, 2)
        else:
            vprint("including body for: " + include_file_path, 2)
            build = vvresub("#include.*" + include_file_path,
                           include_body_match.group(1),
                            build, 3)

#Section: Debug Code
vprint("Section: Debug Code", 0)

#build = vvresub("--debug_start(.|\s)*?--debug_end", "", build, 1)
build = vvresub(".*--debug.*", "", build, 1)

#Section: Comments
vprint("Section: Comments", 0)

build = vvresub("--\[\[(.|\s)*?--]]", "", build, 1)
build = vvresub("--.*", "", build, 1)

#Section: Whitespace
vprint("Section: Whitespace", 0)

#Empty Lines
vprint("Empty Lines", 1)
build = vvresub(re.compile("^(\s+)?$", re.M), "", build, 2)

#Section: Enums
vprint("Section: Enums", 0)

enum_group_re = re.compile("^enum_[^}]*}", re.DOTALL | re.M)
enum_identifier_re = re.compile("(enum_\w+)")
enum_member_re = re.compile("^\s*(\w+)\s*=\s*(\d+)", re.M)

#Section: Function_Maps

#Sections: Unnecessary Tokens

#Sections: Output Build FIle
with open(output_file_name, "w") as output_file:
    output_file.write(build)
    
    



