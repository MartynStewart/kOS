WAIT UNTIL SHIP:LOADED AND SHIP:UNPACKED.
CLEARSCREEN.
CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
COPYPATH("0:/HELLOLAUNCH", "").     //COPY LAUNCH FILE
COPYPATH("0:/HELPERFUNCTIONS", ""). //COPY FILE FULL OF USEFUL FUNCTIONS
RUN ONCE HELPERFUNCTIONS.           //LOAD THE HELPERS
RUN HELLOLAUNCH.                    //RUN IT