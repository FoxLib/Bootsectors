# -*- encoding: utf-8 -*-
import getpass
import os

ms = "  sudo mount disk.img -t vfat -o loop,rw,uid=\""+getpass.getuser()+"\",sync,offset=1048576 disk/";

print "MAKE MOUNT:"
print ms

os.system(ms)
