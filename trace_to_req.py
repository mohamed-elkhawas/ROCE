import re

data_width =16
address_width =30

writes_no = 0
with open("requests_types.txt", "w") as fwt:
    with open("requests_address.txt", "w") as fwa:
        with open("write_data.txt", "w") as fwdw:
            with open("read_data.txt", "w") as fwdr:
                with open("new_memtrace.txt", "r") as fr:
                    lines = fr.readlines()
                    req_number = len(lines)
                    written_values = {} #  addr ,value
                    for i in range(len(lines)):
                        lines[i] = re.split(" ", (re.split("request ", lines[i])[1]))
                        type, addr = lines[i][0], lines[i][2]
                        address = str(bin(int(addr,16)))[2:].zfill(address_width)[-address_width:]
                        if type == "ReadExReq" or type == "ReadSharedReq":
                            try:
                                answer = written_values[address]
                            except:
                                answer = "0"
                            fwdr.writelines(answer+"\n")
                            fwt.writelines("0\n")
                            fwa.writelines( address +"\n")
                        elif type == "WritebackDirty" or type == "WritebackClean":
                            req_number-=1
                            try:
                                answer = written_values[address]
                            except: # the write req didn't show up before
                                req_number += 1
                                answer = str(bin(i * 255))[2:].zfill(data_width)[-data_width:]
                                written_values[address] = answer
                                fwdw.writelines(answer+"\n")
                                fwt.writelines("1\n")
                                fwa.writelines( address + "\n")
                                writes_no += 1
                        else: req_number-=1
                    print("req_number = ",req_number)
                    print("writes_no = ", writes_no)
                    print("reads_no = ", req_number - writes_no )
