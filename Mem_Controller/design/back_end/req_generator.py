
# request format `ADDR_BITS+`INDEX_BITS+`TYPE_BIT+`DATA_BITS 
import random

hex_symb = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'] # hexadecmal symbols
banks = range(16)
burst_lengths = [random.randint(0,16) for i in banks] #we set different burst lengths in each bank


f = open("requests.txt", "w")



for bank , burst_len in zip( banks , burst_lengths):
    #f = open("requests_bank{}".format(bank)+".txt", "w")
    for request in range(burst_len) :
        data = ""
        for bit_index in range(8) : data += hex_symb[random.randint(0,15)] # 32bit
        str = "32'h" + data +",1 "
        f.write(str+" ") #request + valid bit
    str = "32'h"+"0"*8 + ",0"
    f.write(str+'\n') #stoping request with valid zero after the burst
    
    
f.close()  

