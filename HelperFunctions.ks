function doCountdown {
    //FUN COUNTDOWN THAT PRINTS TO THE CONSOLE
    PRINT "Counting down:".
    FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
        PRINT "..." + countdown.
        WAIT 1. // pauses the script here for 1 second.
    }
    PRINT "LAUNCH".
}

function doSafeStage{
    //PROTECTS THE STAGING FROM FIRING MULTIPLE TIMES
    wait until stage:ready.
    stage.
}