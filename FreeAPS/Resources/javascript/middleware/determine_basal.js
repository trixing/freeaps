function middleware(iob, currenttemp, glucose, profile, autosens, meal, reservoir, clock, middlewareSettings) {
    // modify anything
    // return any reason what has changed.
    const hours = clock.getHours();
    const preferences = middlewareSettings.preferences;
    const stats = middlewareSettings.stats;

    const BG = glucose[0].glucose;
    if (!BG) {
        return "Middleware: No valid BG"
    }
    var TDD = preferences.middleware_tdd || 30;
    if (!TDD || TDD <= 0) {
        return "Middleware: TDD <= 0 - disabled"
    }
    if (stats && stats.tdd && stats.tdd.yesterday > 0) {
        console.log("Using TDD from stats service: " + stats.tdd.yesterday);
        TDD = stats.tdd.yesterday;
    }
    const adjustmentFactor = preferences.middleware_adj || 1.0;
    const newIsf = (277700 / (adjustmentFactor  * TDD * BG));
    const profileIsf = profile.sens;
    const newAutosensRatio = Math.max(profile.autosens_min, Math.min(profile.autosens_max, profileIsf / newIsf));
    const orefAutosensRatio = autosens.ratio;

    autosens.ratio = newAutosensRatio;
    /*
    const currentMinTarget = profile.min_bg;
    var exerciseSetting = false;
    var log = "";


    if (profile.high_temptarget_raises_sensitivity == true || profile.exercise_mode == true) {
        exerciseSetting = true;
    }
    */

    return "Middleware: BG" + BG + " TDD " + TDD + " Adj " + adjustmentFactor + " newISF " + newIsf + ", profileISF " + profileIsf + " -> change autosens ratio to " + newAutosensRatio;
}
