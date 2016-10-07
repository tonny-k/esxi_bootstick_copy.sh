# esxi_bootstick_copy.sh
Copy tool for vmware esxi bootsticks

This tool will copy the raw partitions of an esxi bootstick. You may have a 8GB bootstick and most tools will copy it as a raw image that takes 16GB storage. Also the target you copy to, would have to be at least the same size. With this tool, only the actual data will be copied. One example was about 900MB data on a 4GB stick, that was copied onto a 1GB stick. 

Run it on a pc as root that has the required tools. Linux Mint Cinnamon works fine.
Please take care as it can overwrite disks and you can loose data if you are not careful.

More work is required to make it a decent tool.

