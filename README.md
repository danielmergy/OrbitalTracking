# OrbitalTracking

This Project is using Arduino MKR VIDOR 4000 for implementing an Orbital Tracking system on a commercial confocal microscope.
Pulse counting and Burst Serch is implemented within the FPGA in Verilog.
Orbital Tracking algorithm is implemented in C++ within the MCU.
The System is controlled by a Python App.


Has been coded with the help of:

Quartus (Verilog):
https://www.intel.com/content/www/us/en/software-kit/785086/intel-quartus-prime-lite-edition-design-software-version-22-1-2-for-windows.html?

Arduino IDE (C++);
https://www.arduino.cc/en/software

Spyder (Python):
https://www.anaconda.com/


The Arduino Folder should contain
-jtag.c
-jtag.h
-Arduino Sketch
-app.h

app.h is converted from ttf file compiled in QuartusProject by using :
https://github.com/HerrNamenlos123/bytereverse

More information on :
https://systemes-embarques.fr/wp/archives/arduino-mkr-vidor-4000-presentation-et-mise-en-route/


