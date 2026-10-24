// Remote event regression checks. Native tvOS focus still needs a device check.
const fs = require('fs'), path = require('path'), assert = require('assert');
const ts = require('typescript'), React = require('react'), renderer = require('react-test-renderer');
const { act } = renderer;
let eventHandler, backHandler, controls, focused = true, focusRequests = 0, timers = [];
const nativeNavigation = { requestTVFocus() { focusRequests++; controls.markNavigationFocus(); } };
const source = fs.readFileSync(path.join(__dirname, '../components/TVFocusScope.tsx'), 'utf8');
const output = ts.transpileModule(source, { compilerOptions: {
  jsx: ts.JsxEmit.React, module: ts.ModuleKind.CommonJS, esModuleInterop: true,
} }).outputText;
const scopeModule = { exports: {} };
const mockedRequire = id => {
  if (id === 'react-native') return {
    findNodeHandle: () => 42,
    useTVEventHandler: handler => { eventHandler = handler; },
    BackHandler: { addEventListener: (_, handler) => { backHandler = handler; return { remove() {} }; } },
  };
  if (id === '@react-navigation/native') return { useIsFocused: () => focused };
  if (id === '@/constants/TVTheme') return { isAppleTV: true };
  return require(id);
};
new Function('require', 'module', 'exports', 'setTimeout', 'clearTimeout', output)(
  mockedRequire, scopeModule, scopeModule.exports,
  callback => { timers.push(callback); return timers.length; }, () => {},
);
const { TVFocusScope, TVNavigationFocus } = scopeModule.exports;
function Probe() {
  controls = React.useContext(TVNavigationFocus);
  React.useEffect(() => { controls.registerNavigation(nativeNavigation); }, [controls.registerNavigation]);
  return null;
}
const tree = () => React.createElement(TVFocusScope, null, React.createElement(Probe));
const flush = () => { const callbacks = timers; timers = []; callbacks.forEach(fn => fn()); };
let root;
act(() => { root = renderer.create(tree()); });
controls.markContentFocus(true);
act(() => { eventHandler({ eventType: 'up', eventKeyAction: 1 }); flush(); });
assert.equal(focusRequests, 1, 'Siri Remote tap on key release must return to navigation');
controls.markContentFocus(false);
act(() => { eventHandler({ eventType: 'up', eventKeyAction: 1 }); flush(); });
assert.equal(focusRequests, 1, 'other rows should keep directional navigation');
controls.markContentFocus(true);
act(() => { eventHandler({ eventType: 'swipeUp' }); flush(); });
assert.equal(focusRequests, 2, 'first-row touchpad swipe returns to navigation');
controls.markContentFocus(false);
act(() => { assert.equal(backHandler(), true); flush(); });
assert.equal(focusRequests, 3, 'Back from content returns to navigation');
assert.equal(backHandler(), false, 'Back from navigation remains available to router');
let filterFocusRequests = 0;
act(() => { controls.registerContentEntry({ requestTVFocus: () => { filterFocusRequests++; } }); });
controls.markContentFocus(true);
act(() => { eventHandler({ eventType: 'up', eventKeyAction: 1 }); flush(); });
assert.equal(filterFocusRequests, 1, 'first poster row must return to its filter toolbar before main navigation');
assert.equal(focusRequests, 3, 'filter toolbar must not be skipped');
act(() => { assert.equal(backHandler(), true); flush(); });
assert.equal(focusRequests, 4, 'Back from filters returns to main navigation');
focused = false;
act(() => root.update(tree()));
controls.markContentFocus(true);
act(() => { eventHandler({ eventType: 'up', eventKeyAction: 1 }); flush(); });
assert.equal(focusRequests, 4, 'hidden screens must not steal focus');
act(() => root.unmount());
console.log('Key-release, swipe, Back, and hidden-screen focus checks passed');
