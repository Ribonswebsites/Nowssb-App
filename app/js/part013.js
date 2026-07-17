
function openHealthGender(gender) {
  /* closeSub('health-journey') then openSub() 60ms later left a real window
     where NEITHER screen was open — sub-health-journey slides itself away on
     its own transition while nothing has even started opening yet, fully
     uncovering the app underneath for that whole gap. navFromSub (part049.js)
     is the app's established fix for exactly this: open the destination
     first so it covers home, raise it above the source, then drop the
     source once its slide-out is done — smooth animated transition, no
     flash. */
  if (typeof navFromSub === 'function') {
    navFromSub('health-journey', function () { openSub('health-' + gender); });
  } else {
    closeSub('health-journey');
    openSub('health-' + gender);
  }
}
