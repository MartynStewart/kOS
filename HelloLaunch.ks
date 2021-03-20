
set turn_start_altitude to 1000.    //What height we want to start our gravity turn
set turn_end_altitude to 40000.     //What height we want to be horizontal firing

main().


function main {
    launch().
    doAscent().
    until apoapsis > 100000 doAutoStage().
    doShutdown().
    executeManeuver(time:seconds + 30, 100, 100, 100).
    print "code ran fully".
    wait until false.
}

function launch{
    lock throttle to 1.
    doCountdown().
    doSafeStage().
}

function doCountdown {
    PRINT "Counting down:".
    FROM {local countdown is 5.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
        PRINT "..." + countdown.
        WAIT 1. // pauses the script here for 1 second.
    }
    PRINT "LAUNCH".
}

function doSafeStage{
    wait until stage:ready.
    stage.
}

function doAutoStage{
    if not(defined oldThrust){
        declare global oldThrust to ship:availablethrust.
    }

    if ship:availablethrust < (oldThrust - 10) {
        doSafeStage().
        wait 1.
        declare global oldThrust to ship:availablethrust.
    }
}

function doAscent{
    //lock targetPitch to (90 - (90 * SQRT(MAX(0, SHIP:ALTITUDE - turn_start_altitude) / turn_end_altitude))).
    lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
    set targetDirection to 90.
    lock steering to heading(targetDirection, targetPitch).
    set oldThrust to ship:avaiLablethrUST.
}

function doShutdown{
    lock throttle to 0.
    lock steering to prograde.
}

function  executeManeuver {
    parameter utime, radial, normal, pgrade.
    local mnv is node(utime, radial, normal, pgrade).
    addManeuverToFlightPlan(mnv).
    local startTime is calculateStartTime(mnv).
    wait until time:seconds > startTime - 10.
    lockSteeringAtManeuverTarget(mnv).
    wait until time:seconds > startTime.
    lock throttle to 1.
    wait until isManeuverComplete(mnv).
    lock throttle to 0.
    removeManeuverFromFlightPlan(mnv).
}

function addManeuverToFlightPlan{
    parameter mnv.
    add mnv.
    wait 1.
}

function calculateStartTime{
    parameter mnv.
    local mETA is mnv:eta.
    local startSplit is maneuverBurnTime(mnv) / 2.

    return time:seconds + mETA - startSplit.
}

function maneuverBurnTime{
    parameter mnv.
    //TODO
    return 10.
}

function lockSteeringAtManeuverTarget{
    parameter mnv.
    lock steering to mnv:burnvector.
}

function isManeuverComplete{
    print "Checking is complete".
    parameter mnv.
    if not(defined originalVector) or originalVector = -1 {
        declare global originalVector to mnv:burnvector.
    }
    if vAng(originalVector, mnv:burnvector) > 90 {
        declare global originalVector to -1.
        return true.
    }
    return false.
}

function removeManeuverFromFlightPlan{
    parameter mnv.
    print "Removing it".
    remove mnv.
}

