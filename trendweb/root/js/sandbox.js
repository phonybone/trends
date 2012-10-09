
function fart() {
var o={fred:1};
o.fred='fart';

console.log()
fredtype=typeof o.fred
console.log('typeof o.fred: '+fredtype);

if (fredtype == "undefined") {
  console.log('sb: o.fred is not defined')
} else {
  console.log('sb: o.fred is defined: ' + o.fred);
}
for (k in o) {
  console.log(k+': '+o[k])
}
console.log(o)

}
