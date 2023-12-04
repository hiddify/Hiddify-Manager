# Resource control hiddify 

import os 
from datetime import datetime
from dateutil import tz
from time import sleep

def USEDISK():
    while True:
        # With the implementation of this loop, the time is checked every 1800 seconds. 
        # If the time is between 5 and 6 in the morning, the commands are executed

        sleep(1800)
        localisedDatetime = datetime.now(tz = tz.tzlocal())
        if localisedDatetime.hour == 5 or 6: 
            os.system("sudo journalctl --vacuum-time=1d")
            sleep(10)   
            os.system("rm -rf /opt/hiddify-config/log/system/*") 
            # By executing the above command, the disk logs will be deleted
            sleep(10) 
            os.system('free && sync && echo 3 > /proc/sys/vm/drop_caches && free')
            # Clear the RAM cache

        else:
            pass

try: 
    USEDISK()
except KeyboardInterrupt: 
    exit() 
