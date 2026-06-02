
function openHealthGender(gender) {
  closeSub('health-journey');
  setTimeout(() => openSub('health-' + gender), 60);
}
