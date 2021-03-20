
global turn_start_altitude to 1000.    //What height we want to start our gravity turn
global turn_end_altitude to 40000.     //What height we want to be horizontal firing

main().


function main {
    launch().
    doAscent().
    until apoapsis > 100000 doAutoStage().
    doShutdown().
    doCirculisation().
    //doTransfer().
    print "Code Complete".
}

function launch{
    lock throttle to 1.
    doCountdown().
    doSafeStage().
}

function doAutoStage{
    if not(defined oldThrust){
        declare global oldThrust to ship:availablethrust.
    }

    if ship:availablethrust < (oldThrust - 10) {
        until false {
            doSafeStage().
            wait 1.
            if (ship:availablethrust > 0) {
                break.
            }
        }
        declare global oldThrust to ship:availablethrust.
    }
}

function weHaveThrust{

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
    parameter mList.
    local mnv is node(mList[0], mList[1], mList[2], mList[3]).
    addManeuverToFlightPlan(mnv).
    local startTime is calculateStartTime(mnv).
    lockSteeringAtManeuverTarget(mnv).
    wait until time:seconds > startTime.
    lock throttle to max(min(mnv:burnvector:mag / (ship:availablethrust / ship:mass),1),0.005).     //Gentler throttling
    until isManeuverComplete(mnv){
        doAutoStage().
    }
    lock throttle to 0.
    removeManeuverFromFlightPlan(mnv).
    lock steering to prograde.
}

function addManeuverToFlightPlan{
    parameter mnv.
    add mnv.
}

function removeManeuverFromFlightPlan{
    parameter mnv.
    remove mnv.
}

function calculateStartTime{
    parameter mnv.
    local mETA is mnv:eta.
    local startSplit is maneuverBurnTime(mnv) / 2.

    return time:seconds + mETA - startSplit.
}

function maneuverBurnTime{
    parameter mnv.

    local dV is mnv:deltaV:mag.
    local g0 is 9.80665.
    local isp is 0.

    list engines in myEngines.
    for en in myEngines{
        if en:ignition and not en:flameout{
            set isp to isp + (en:isp * en:availableThrust / ship:availableThrust).
        }
    }

    local mf is ship:mass / (constant():e ^ (dV / (isp * g0))).
    local fuelFlow is ship:availableThrust / (isp * g0).
    local t is (ship:mass - mf) / fuelFlow.

    return t.
}

function lockSteeringAtManeuverTarget{
    parameter mnv.
    lock steering to mnv:burnvector.
}

function isManeuverComplete{
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

function doCirculisation{
    local circ is list(time:seconds+30,0).
    set circ to improveConverge(circ, eccentricityScore@).
    executeManeuver(list(circ[0],0,0,circ[1])).
}

function doTrasfer{
    local transfer is list(time:seconds+30,0,0,0).
    set transfer to improveConverge(transfer, munTransferScore@).
    executeManeuver(transfer).
}

function eccentricityScore{
    parameter data.
    local mnv is node(data[0], 0, 0, data[1]).
    addManeuverToFlightPlan(mnv).
    local result is mnv:orbit:eccentricity.
    removeManeuverFromFlightPlan(mnv).
    return result.
}

function munTransferScore{
    parameter data.
    local mnv is node(data[0], data[1], data[2], data[3]).
    addManeuverToFlightPlan(mnv).
    local result is mnv:orbit:eccentricity.
    removeManeuverFromFlightPlan(mnv).
    return result.
}

function improveConverge{
    parameter data, scoreFunction.
    for stepSize in list(100, 10, 1){
        until false{
            local oldScore is scoreFunction(data).
            set data to improve(data, stepSize, scoreFunction).
            if oldscore <= scoreFunction(data){
                break.
            }
        }
    }
    return data.
}

function improve{
    parameter data, stepSize, scoreFunction.
    local scoreToBeat is scoreFunction(data).
    local bestCandidate is data.

    local candidates is list().
    local index is 0.
    until index >= data:length{
        local incCandidate is data:copy().
        local decCandidate is data:copy().
        set incCandidate[index] to incCandidate[index]+stepSize.
        set decCandidate[index] to decCandidate[index]-stepSize.
        candidates:add(incCandidate).
        candidates:add(decCandidate).
        set index to index + 1.
    }

    for candidate in candidates{
        local candidateScore is scoreFunction(candidate).
        if candidateScore< scoreToBeat{
            set scoreToBeat to candidateScore.
            set bestCandidate to candidate.
        }
    }

    return bestCandidate.
}
