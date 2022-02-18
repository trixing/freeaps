//для enact/smb-suggested.json параметры: monitor/iob.json monitor/temp_basal.json monitor/glucose.json settings/profile.json settings/autosens.json --meal monitor/meal.json --microbolus --reservoir monitor/reservoir.json

function generate(iob, currenttemp, glucose, profile, autosens = null, meal = null, microbolusAllowed = false, reservoir = null, clock = new Date(),
                  middleware_settings = {}) {
    if (!clock) {
        clock = new Date(); // Date object from swift doesn't work
    }
    try {
        console.log("Middleware settings: %o", middleware_settings);
        var middlewareReason = middleware(iob, currenttemp, glucose, profile, autosens, meal, reservoir, clock, middleware_settings);
        console.log("Middleware reason: " + (middlewareReason || "Nothing changed"));
    } catch (error) {
        console.log("Invalid middleware: " + error);
    }

    var glucose_status = freeaps_glucoseGetLast(glucose);
    var autosens_data = null;

    if (autosens) {
        autosens_data = autosens;
    }

    var reservoir_data = null;
    if (reservoir) {
        reservoir_data = reservoir;
    }

    var meal_data = {};
    if (meal) {
        meal_data = meal;
    }

    return freeaps_determineBasal(glucose_status, currenttemp, iob, profile, autosens_data, meal_data, freeaps_basalSetTemp, microbolusAllowed, reservoir_data, clock);
}
