function middleware(iob, currenttemp, glucose, profile, autosens, meal, reservoir, clock, middlewareSettings) {
    const adjustmentFactor = 1.0;
    const TDD = 0;
    if (!TDD || !adjustmentFactor) {
        return "Middleware disabled";
    }

    const preferences = middlewareSettings.preferences;
    const stats = middlewareSettings.stats;
    if (stats.tdd && stats.tdd.weighted > 0) {
        var newTDD = stats.tdd.weighted;
        // some safety limits
        if ((newTDD > 0.5*TDD) && (newTDD < 2*TDD)) {
            console.log("Using weighted TDD from stats service: " + newTDD);

            TDD = newTDD;
        } else {
            console.log("Weighted TDD out of bounds: " + newTDD);
            return "Middleware, weighted TDD out of bounds: " + newTDD;
        }
    }

    const bg = glucose[0].glucose;

    if (!bg) {
        return "Middleware, No blood glucose";
    }
    if (profile.min_bg > 115) {
        return "Middleware, High target set";
    }
    var newISF = 277700 / (adjustmentFactor  * TDD * bg);
    var newRatio = profile.sens / newISF;
    if (newRatio < profile.autosens_min) {
        newRatio = profile.autosens_min;
    }
    if (newRatio > profile.autosens_max) {
        newRatio = profile.autosens_max;
    }
    autosens.ratio = newRatio;
    return "Middleware, adjusting ISF to " + newISF + " with ratio " + newRatio;
}
