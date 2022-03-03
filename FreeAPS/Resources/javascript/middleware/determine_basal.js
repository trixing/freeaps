function middleware(iob, currenttemp, glucose, profile, autosens, meal, reservoir, clock) {
    const adjustmentFactor = 1.0;
    const TDD = 0;
    if (!TDD || !adjustmentFactor) {
        return "Middleware disabled";
    }

    // Should not need configuring below.
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
