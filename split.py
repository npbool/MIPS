f1 = open("ram1.data","w")
f2 = open("ram2.data","w")
row=1
f1.write("%d=%s\n"%(0,"0000"));
f2.write("%d=%s\n"%(0,"0000"));

while(True):
    line = raw_input()
    if line[0]=='#':
        break
    parts = line.split(' ')
    f1.write("%X=%s\n"%(row,parts[1][0:4]))
    f2.write("%X=%s\n"%(row,parts[1][4:8]))
    row += 1
    
f1.close();
f2.close();